    function widget:GetInfo()
            return {
                            name    = "modding/debug Show Unit ID and projectiles",
                            desc    = "Show all ID of units, features, projectiles",
                            author  = "zwzsg, knorke",
                            date    = "August 2010",
                            license = "Free, run, jump- play with the other software packages. What do you mean, you want to hold slaves?",
                            layer   = 0,
                            enabled = false,
							hidden = true
                    }
    end
     
     
function widget:DrawScreenEffects()
		for _,id in ipairs(Spring.GetAllUnits()) do
				local x,y=Spring.WorldToScreenCoords(Spring.GetUnitPosition(id))
				local FontSize=16
				gl.Text("U:"..id,x,y,16,"od")
		end
		
		
		for _,id in ipairs(Spring.GetVisibleProjectiles()) do
				local x,y=Spring.WorldToScreenCoords(Spring.GetProjectilePosition(id) )
				local FontSize=16
				gl.Text("P:"..id,x,y,16,"od")
		end

		for _,id in ipairs(Spring.GetVisibleFeatures ()) do
				local x,y=Spring.WorldToScreenCoords(Spring.GetFeaturePosition(id) )
				local FontSize=16
				gl.Text("F:"..id,x,y,16,"od")
		end		
		


end