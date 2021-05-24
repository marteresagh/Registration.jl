# function subpotree(potree::String, model::Common.LAR)
# 	flushprintln(" ")
#     flushprintln("======== PROJECT $potree ========")
# 	metadata = FileManager.CloudMetadata(potree) # metadata of current potree project
#
# 	trie = FileManager.potree2trie(potree)
# 	l = length(keys(trie))
#
# 	# if model contains the whole point cloud ( == 2)
# 	#	process all files
# 	# else
# 	# 	navigate potree
# 	intersection = Common.modelsdetection(model, metadata.tightBoundingBox)
# 	if intersection == 2
# 		flushprintln("FULL model")
# 		files = FileManager.get_all_values(trie)
# 		return files
# 	elseif intersection == 1
# 		flushprintln("DFS")
# 		# nfiles = total files processed
# 		files = dfs(trie,model)
# 		return files
# 	elseif intersection == 0
# 		flushprintln("OUT OF REGION OF INTEREST")
# 		return nothing
# 	end
#
# end
#
#
#
# """
# 	dfs(t::DataStructures.Trie{String},
# 	params::Union{ParametersOrthophoto,ParametersExtraction},
# 	s::Union{Nothing,IOStream},n::Int64,nfiles::Int64,l::Int64)
#
# Depth search first.
# """
# function dfs(trie::FileManager.DataStructures.Trie{String},
# 	model::Common.LAR, files = String[])
#
# 	file = trie.value # path to node file
# 	nodebb = FileManager.las2aabb(file) # aabb of current octree
# 	inter = Common.modelsdetection(model, nodebb)
#
# 	if inter == 1
# 		# intersecato ma non contenuto
# 		# alcuni punti ricadono nel modello altri no
#
# 		push!(files,file)
# 		for key in collect(keys(trie.children)) # for all children
# 			files = dfs(trie.children[key],model, files)
# 		end
#
# 	elseif inter == 2
# 		# contenuto: tutti i punti del albero sono nel modello
# 		for k in keys(trie)
# 			file = trie[k]
# 			push!(files,file)
# 		end
# 	end
# 	return files
# end
#
#
#
# """
# 	trie_traversal(params::Union{ParametersExtraction,ParametersOrthophoto},s::Union{Nothing,IOStream})
#
# Trie traversal.
# If entire point cloud falls in volume process all files of Potree project
# else travers trie, depth search first, and process nodes falling in region of interest.
#
# Input:
#  - params: initial parameters
#  - s: nothing or stream file where to save las points
#
# Output:
# - n: number of processed points
# """
# function trie_traversal(potree::String, model::Common.LAR)
#
# 	n = 0 # total points processed
# 	l = nothing # total files to process
# 
#     for potree in params.potreedirs
# 		flushprintln(" ")
#         flushprintln("======== PROJECT $potree ========")
# 		metadata = CloudMetadata(potree) # metadata of current potree project
#
# 		trie = potree2trie(potree)
# 		l = length(keys(trie))
#
# 		# if model contains the whole point cloud ( == 2)
# 		#	process all files
# 		# else
# 		# 	navigate potree
# 		intersection = Common.modelsdetection(params.model, metadata.tightBoundingBox)
# 		if intersection == 2
# 			flushprintln("FULL model")
# 			i = 1
# 			for k in keys(trie)
# 				if i%100==0
# 					flushprintln(i," files processed of ",l)
# 				end
# 				file = trie[k]
# 				n = update!(params,file,s,n)
# 				i = i+1
# 			end
# 		elseif intersection == 1
# 			flushprintln("DFS")
# 			# nfiles = total files processed
# 			n,nfiles = dfs(trie,params,s,n,0,l)
#
# 			if l-nfiles > 0
# 				flushprintln("$(l-nfiles) file of $l not processed - out of region of interest")
# 			end
#
# 		elseif intersection == 0
# 			flushprintln("OUT OF REGION OF INTEREST")
# 		end
# 	end
#
# 	return n
# end
#
#
# """
# 	dfs(t::DataStructures.Trie{String},
# 	params::Union{ParametersOrthophoto,ParametersExtraction},
# 	s::Union{Nothing,IOStream},n::Int64,nfiles::Int64,l::Int64)
#
# Depth search first.
# """
# function dfs(trie::DataStructures.Trie{String},
# 	params::Union{ParametersOrthophoto,ParametersExtraction},
# 	s::Union{Nothing,IOStream},n::Int64,nfiles::Int64,l::Int64)
#
# 	file = trie.value # path to node file
# 	nodebb = FileManager.las2aabb(file) # aabb of current octree
# 	inter = Common.modelsdetection(params.model, nodebb)
#
# 	if inter == 1
# 		# intersecato ma non contenuto
# 		# alcuni punti ricadono nel modello altri no
# 		nfiles = nfiles + 1
# 		if nfiles%100==0
# 			flushprintln(nfiles," files processed of ",l)
# 		end
#
# 		n = updateif!(params,file,s,n) # update with check
#
# 		for key in collect(keys(trie.children)) # for all children
# 			n,nfiles = dfs(trie.children[key],params,s,n,nfiles,l)
# 		end
#
# 	elseif inter == 2
# 		# contenuto: tutti i punti del albero sono nel modello
# 		for k in keys(trie)
# 			nfiles = nfiles+1
#
# 			if nfiles%100==0
# 				flushprintln(nfiles," files processed of ",l)
# 			end
#
# 			file = trie[k]
# 			n = update!(params,file,s,n) # update without check
# 		end
# 	end
#
# 	return n,nfiles
# end
