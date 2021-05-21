function subpotree(potree::String, model::Common.LAR)
	flushprintln(" ")
    flushprintln("======== PROJECT $potree ========")
	metadata = FileManager.CloudMetadata(potree) # metadata of current potree project

	trie = FileManager.potree2trie(potree)
	l = length(keys(trie))

	# if model contains the whole point cloud ( == 2)
	#	process all files
	# else
	# 	navigate potree
	intersection = Common.modelsdetection(model, metadata.tightBoundingBox)
	if intersection == 2
		flushprintln("FULL model")
		files = FileManager.get_all_values(trie)
		return files
	elseif intersection == 1
		flushprintln("DFS")
		# nfiles = total files processed
		files = dfs(trie,model)
		return files
	elseif intersection == 0
		flushprintln("OUT OF REGION OF INTEREST")
		return nothing
	end

end



"""
	dfs(t::DataStructures.Trie{String},
	params::Union{ParametersOrthophoto,ParametersExtraction},
	s::Union{Nothing,IOStream},n::Int64,nfiles::Int64,l::Int64)

Depth search first.
"""
function dfs(trie::FileManager.DataStructures.Trie{String},
	model::Common.LAR, files = String[])

	file = trie.value # path to node file
	nodebb = FileManager.las2aabb(file) # aabb of current octree
	inter = Common.modelsdetection(model, nodebb)

	if inter == 1
		# intersecato ma non contenuto
		# alcuni punti ricadono nel modello altri no

		# push!(files,file)
		for key in collect(keys(trie.children)) # for all children
			files = dfs(trie.children[key],model, files)
		end

	elseif inter == 2
		# contenuto: tutti i punti del albero sono nel modello
		for k in keys(trie)
			file = trie[k]
			push!(files,file)
		end
	end
	return files
end
