#!/usr/bin/env python3
"""Render MOSAIC's original 80-second procession loop (NumPy and ffmpeg).

No sampled recordings: drums, woodblocks, bells, reed and organ are synthesized.
Note tails and stereo echoes wrap around the 32-bar cycle for a continuous loop.
The fixed seed makes composition and synthesis reproducible.
"""
from pathlib import Path
import argparse
import math
import os
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
BPM = 96
BEAT = 60 / BPM
BARS = 32
SECONDS = BARS * 4 * BEAT
FRAMES = round(SECONDS * RATE)
RNG = np.random.default_rng(707)


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def envelope(t, duration, attack=0.008, release=0.04):
    return np.minimum(t / attack, 1) * np.minimum(np.maximum(duration-t, 0) / release, 1)


def bell(midi, duration=2.8):
    t = np.arange(round(duration * RATE)) / RATE
    f = frequency(midi)
    # Soft struck metal with tuned upper partials, not a bright alarm chime.
    signal = (np.sin(2*math.pi*f*t)*np.exp(-2.5*t)
              + .32*np.sin(2*math.pi*f*2*t)*np.exp(-3.8*t)
              + .12*np.sin(2*math.pi*f*3.98*t)*np.exp(-7*t))
    return signal * envelope(t, duration, attack=.003)


def reed(midi, duration):
    t = np.arange(round(duration * RATE)) / RATE
    f = frequency(midi)
    phase = 2*math.pi*f*t + .025*np.sin(2*math.pi*4.4*t)
    signal = np.sin(phase) + .15*np.sin(2*phase) + .07*np.sin(3*phase)
    return signal * envelope(t, duration, attack=.08, release=.18) * np.exp(-.3*t)


def pluck(midi, duration=1.0):
    t = np.arange(round(duration * RATE)) / RATE
    f = frequency(midi)
    signal = sum((1 / harmonic**1.7)*np.sin(2*math.pi*f*harmonic*t)
                 *np.exp(-(3+.65*harmonic)*t) for harmonic in range(1, 7))
    return signal * envelope(t, duration, attack=.002)


def drum(deep=True, duration=.6):
    t = np.arange(round(duration * RATE)) / RATE
    fundamental = 48 if deep else 104
    sweep = 65 if deep else 105
    phase = 2*math.pi*(fundamental*t+sweep*.025*(1-np.exp(-t/.025)))
    body = np.sin(phase)*np.exp(-t/(.17 if deep else .095))
    noise = RNG.normal(0, 1, len(t))
    noise = np.convolve(noise, np.ones(9)/9, mode='same')
    return (body+.21*noise*np.exp(-t/.02))*envelope(t, duration, attack=.001)


def wood(duration=.12):
    t = np.arange(round(duration * RATE))/RATE
    return (.7*np.sin(2*math.pi*830*t)+.3*np.sin(2*math.pi*1261*t)) \
        *np.exp(-t/.018)*envelope(t, duration, attack=.001, release=.01)


def organ(chord, duration):
    t = np.arange(round(duration * RATE))/RATE
    result = np.zeros(len(t))
    for midi in chord:
        f = frequency(midi)
        result += (np.sin(2*math.pi*f*t)
                   + .2*np.sin(2*math.pi*2*f*t)
                   + .09*np.sin(2*math.pi*3*f*t)) / len(chord)
    return result*envelope(t, duration, attack=.5, release=.7)


def add(stem, signal, beat, volume, pan=0):
    start = round(beat*BEAT*RATE) % FRAMES
    # Equal-power stereo panning; modulo addition retains late-note tails.
    gain = volume*np.array([math.cos((pan+1)*math.pi/4), math.sin((pan+1)*math.pi/4)])
    stereo = signal[:, None]*gain
    split = min(len(signal), FRAMES-start)
    stem[start:start+split] += stereo[:split]
    if split < len(signal):
        stem[:len(signal)-split] += stereo[split:]


def compose():
    dry = np.zeros((FRAMES, 2), dtype=np.float32)
    tonal = np.zeros_like(dry)
    # D minor pentatonic; each eight-bar circuit rises and settles on D.
    roots = [38,38,41,41,43,43,38,38]
    chords = [[50,57,60], [50,57,65], [53,60,65], [53,57,62],
              [43,55,62], [43,57,62], [50,57,65], [50,57,62]]
    phrases = [
        [(0,74,1.3),(1.5,77,.8),(3,81,.7)],
        [(0,79,1),(1.5,77,1),(3,74,.8)],
        [(0,72,1.2),(2,74,.7),(3,77,.8)],
        [(0,81,1.3),(2,79,1.4)],
        [(0,79,.8),(1,81,.8),(2.5,84,1)],
        [(0,81,1),(1.5,79,.8),(3,77,.7)],
        [(0,74,1.4),(2,72,.8),(3,69,.8)],
        [(0,72,.8),(1.5,74,2)],
    ]
    deep, high, block = drum(True), drum(False), wood()
    for bar in range(BARS):
        cycle, phrase = divmod(bar, 8)
        base = bar*4
        # Processional pace: the two low footfalls stay stable throughout.
        add(dry, deep, base, .24)
        add(dry, deep, base+2, .18)
        add(dry, high, base+1, .075, -.23)
        add(dry, high, base+3, .095, .23)
        for beat in ([.75,2.75] if cycle in (0,3) else [.75,1.5,2.75,3.5]):
            add(dry, block, base+beat, .026 if beat%1==.75 else .019, (-1 if beat<2 else 1)*.4)
        if phrase==7:
            add(dry, high, base+3.5, .06, -.3)
            add(dry, high, base+3.75, .04, .3)

        add(tonal, organ(chords[phrase],4*BEAT+.25), base, .105)
        for beat in (0,2):
            add(tonal, reed(roots[phrase],1.2*BEAT), base+beat, .09)
        for beat, midi, length in phrases[phrase]:
            # Second half adds an answering bell/wooden pluck, retaining air.
            add(tonal, reed(midi-12,length*BEAT), base+beat, .065 if cycle!=2 else .045, -.12)
            add(tonal, bell(midi), base+beat, .045, .28)
            if cycle in (1,2) and beat<3:
                answer = midi-12 if cycle==1 else midi
                add(tonal, pluck(answer), base+beat+.5, .042, -.32)
        if phrase in (0,4):
            add(tonal, bell(86 if phrase==0 else 81,4), base, .025, -.4)
        if cycle==2:
            for beat,midi in ((.5,74),(2.5,69)):
                add(tonal, pluck(midi), base+beat, .022, .4)

    # Wrapped cross-channel echoes and short room reflections preserve the seam.
    mix = dry + tonal
    for delay, gain in ((.187,.12),(.375,.13),(.625,.11),(1.25,.07),(1.875,.035)):
        shifted = np.roll(tonal[:,::-1],round(delay*RATE),axis=0)
        mix += shifted*gain
    mix += np.roll(dry,round(.071*RATE),axis=0)*.06
    mix += np.roll(dry[:,::-1],round(.113*RATE),axis=0)*.035
    mix = np.tanh(mix*1.4)
    mix -= mix.mean(axis=0)
    mix *= .78 / np.max(np.abs(mix))
    return mix


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path,
        default=ROOT/'sounds/music/parade/seventh_night_procession.ogg')
    args=parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    samples=compose()
    pcm=(samples*32767).astype('<i2')
    with tempfile.TemporaryDirectory(prefix='mosaic-parade-score-') as temp:
        wav=Path(temp)/'procession.wav'
        encoded=Path(temp)/'procession.ogg'
        with wave.open(str(wav),'wb') as f:
            f.setnchannels(2); f.setsampwidth(2); f.setframerate(RATE)
            f.writeframes(pcm.tobytes())
        subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',
            '-metadata','title=Seventh Night Procession',
            '-metadata','artist=MOSAIC procedural instrumental',
            '-metadata','comment=Original synthesized score; 96 BPM; 32 bars; 80 second cyclic loop; no sampled recordings',
            str(encoded)],check=True)
        with args.output.open('wb') as target:
            target.write(encoded.read_bytes())
            target.flush()
            os.fsync(target.fileno())
    rms=float(np.sqrt(np.mean(samples*samples)))
    seam=float(np.max(np.abs(samples[0]-samples[-1])))
    print(f'{args.output}: {SECONDS:.1f}s stereo, peak {np.max(np.abs(samples)):.3f}, RMS {rms:.3f}, seam step {seam:.6f}')

if __name__=='__main__':
    main()
