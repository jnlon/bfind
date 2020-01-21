#!/usr/bin/env lua

-- bfind: like a very simple version of the classic unix find command,
-- but prints directory entries breadth-first rather than depth-first

-- requires module 'luafilesystem'
lfs = require('lfs')

-- usage string
USAGE='Usage: bfind [path]'

-- return true if path points to a directory
function is_directory(path)
	return lfs.symlinkattributes(path, 'mode') == 'directory'
end

-- return a sorted table of diretories at path 'where'
function dir_sorted(where) 
	-- read directory entries in a pcall() closure to prevent fatal errors
	-- (eg, missing read permission on directory). append entries from
	-- directory 'where' to table 'paths' as we read them
	local paths = {}
	local success = pcall(function()
		for entry in lfs.dir(where) do
			local dots = (entry == '.' or entry == '..')
			if not dots then table.insert(paths, where .. entry) end
		end
	end)
	-- check the result of the pcall function
	if not success then 
		io.stderr:write('Failed to enumerate directory: ' .. where .. '\n') 
	end
	-- sort the paths and return
	table.sort(paths)
	return paths
end

-- Main program flow, a recursive function. Each recursive call represents drilling down
-- another level down the file system tree. We print all entries for a given level
-- in batches (implemented by the inner for loop) before recursing to the next level. Each
-- batch represents all filesystem entries 'n' levels down regardless of their parent
function breadth_walk(seed_dirs)
	local next_seed_dirs = {} -- directories on next level down file system tree, entrypoints to the next batch
	for i=1, #seed_dirs do
		for _, entry in ipairs(dir_sorted(seed_dirs[i])) do
			if is_directory(entry) then 
				entry = entry .. '/'
				table.insert(next_seed_dirs, entry) -- save this directory entry for the next recurse
			end
			print(entry)
		end
	end
	-- if there are more dirs on the next level down: recurse to process the next batch
	if #next_seed_dirs > 0 then 
		breadth_walk(next_seed_dirs)
	end
end

-- program entry point, mainly argument handling
function main()
	-- exactly 0 or 1 arguments accepted
	if #arg > 1 then 
		print(USAGE)
		return 1
	end

	-- use cwd if no argument given
	local root = arg[1] or '.'
	-- verify the given path actually a directory
	if not(is_directory(root)) then
		print('Argument "' .. root .. '" is not a directory')
		return 1
	end

	-- strip duplicate trailing slashes
	root = string.gsub(root, '/*$', '/') 

	-- begin walking
	print(root)
	breadth_walk({root})
	return 0
end

os.exit(main())
