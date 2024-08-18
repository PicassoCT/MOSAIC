-- Function to filter lines (Modify this function according to your needs)
function filter_line(line)
    -- Example: only keep lines that contain the word "Lua"
    return string.find(line, "%[\"")
end

function duration_to_ms(duration)
    local hours, minutes, seconds, ms_fraction = duration:match("(%d%d):(%d%d):(%d%d)%.(%d%d)")
    -- Convert captured groups to numbers
    hours = tonumber(hours)
    minutes = tonumber(minutes)
    seconds = tonumber(seconds)
    ms_fraction = tonumber(ms_fraction)

    -- Convert the time to milliseconds
    local total_ms = (hours * 3600000) + (minutes * 60000) + (seconds * 1000) + (ms_fraction * 10)
    return total_ms
end

-- Function to process lines (Modify this function according to your needs)
function process_line(line)
		print("Processing line:"..line)
        local duration_ms = duration_to_ms(line)
        local filename = line:match("%[.+]")
        local resultLine = "["..filename.."] = "..duration_ms..","
    return resultLine
end

-- Main function
function process_file(input_file, output_file)
    -- Open the input file for reading
    local infile = io.open(input_file, "r")
    if not infile then
        print("Error: Could not open input file.")
        return
    end

    -- Open the output file for writing
    local outfile = io.open(output_file, "w")
    if not outfile then
        print("Error: Could not open output file.")
        infile:close()
        return
    end

    -- Process each line
    for line in infile:lines() do
        if filter_line(line) then
            local processed_line = process_line(line)
            outfile:write(processed_line .. "\n")
        end
    end

    -- Close the files
    infile:close()
    outfile:close()

    print("File processing completed.")
end

-- Example usage
local input_file = "result.txt"
local output_file = "filtered.txt"
process_file(input_file, output_file)
