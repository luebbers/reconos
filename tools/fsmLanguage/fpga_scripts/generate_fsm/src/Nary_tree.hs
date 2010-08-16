module Nary_tree(make_tree, make_tree_dot) where

import Data.List

data NTree a =
	NTreeFork a [(NTree a)]
	| NTreeEmpty
	deriving(Show,Eq)

make_tree a = let a' = reverse a in (build_dumb_tree NTreeEmpty a')

build_dumb_tree acc [] = acc
build_dumb_tree acc (a:as) =
  let acc' = (NTreeFork a [acc]) in
		build_dumb_tree acc' as 

-- Boolean function used to check to see if a tree has any contents
has_contents (NTreeEmpty) = False
has_contents (NTreeFork a _) = True

-- Function used to extract a tree's immediate contents (on that level)
get_contents (NTreeFork a _) = a
get_contents (NTreeEmpty) = error "An empty tree has no contents"

-- Function used to extract a tree's immediate children
get_children (NTreeFork a cs) = cs
get_children (NTreeEmpty) = error "An empty tree has no children"

-- Function used to calculate the height of a tree
height (NTreeEmpty) = 0
height (NTreeFork a cs) =
	let hcs = map height cs in
		1 + (foldr f 0 hcs)
	where f a b = if a > b then a else b

-- Function used to extract all "nodes" that are between the root (level 0) and level i (inclusive)
get_level i t = 
  let h = (height t) in
    if (h > i) then
  		accum_levels [] 0 i t
    else
		error "Requested tree does not have enough levels"

-- Helper function for get_level
accum_levels acc cur_lev des_lev (NTreeEmpty) = acc
accum_levels acc cur_lev des_lev (NTreeFork a cs) =
	if (cur_lev > des_lev) then
		acc
	else
		-- Grab the contents of the next levels for each child tree
		let res = map (accum_levels (acc) (cur_lev + 1) (des_lev)) cs in
			-- Accumulate the results and add on the current tree node
			a : (foldr (++) [] res)

-- Function used to get nodes at each level in a tree
level_map t =
   let ids = extract_all t in
	   let rev = rev_tuples [] ids in
           create_map 0 (height t) rev

rev_tuples acc [] = acc
rev_tuples acc ((a,b):cs) =
        let acc' = (b,a):acc in
            rev_tuples acc' cs

create_map curh maxh l =
  -- Stop if the height of the tree has been reached
  if (curh == maxh) then
     []
  else
    -- Get all nodes on current level and add to the map
     let cur_nodes = find_all [] curh l in
        ((cur_nodes) : (create_map (curh + 1) (maxh) l))

find_all acc lev [] = (lev, acc)
find_all acc lev ((l,n):ls) =
   let acc' = if (lev == l) then (n:acc) else acc in
	   (find_all acc' lev ls)

-- Function used to extract all "nodes" and their associated levels
extract_all t = 
	identify_levels [] 0 (height t) t

-- Helper function to get a list of annotated (node,level) pairs
identify_levels acc cur_lev des_lev (NTreeEmpty) = acc
identify_levels acc cur_lev des_lev (NTreeFork a cs) =
	if (cur_lev == des_lev) then
		acc
	else
		-- Grab the contents of the next levels for each child tree
		let res = map (identify_levels (acc) (cur_lev + 1) (des_lev)) cs in
			-- Combine the results and add on the current tree node
			((a,cur_lev) : (foldr (++) [] res))

             
             

-- Function used to search for a given "node" in the tree (earliest first)
search_for_item des t =
  let res = find_item des t in
      if (res == []) then
		error "Item not found!"
	  else
		(res)

-- Function used to find a given "node" in a tree (returns a list)
find_item des t = find_item_helper [] des t

find_item_helper acc des (NTreeEmpty) = acc
find_item_helper acc des (NTreeFork a cs) =
  let acc' =  if (a == des) then (a:acc) else acc
      accs = foldr (++) [] (map (find_item_helper acc des) cs)
      in
		acc'++accs 

-- Function used to "dotify" a tree
make_tree_dot t =
  unlines [
			"digraph G {",
			dotify_tree t,
			"}"
		 ]	

dotify_tree (NTreeEmpty) = []
dotify_tree (NTreeFork a cs) =
  let dc = unlines $ gen_dc a cs in
	unlines [
			(show a),
			dc,
			concatMap dotify_tree cs
			]

gen_dc a cs = map (gen_direct_children a) cs
     
gen_direct_children :: (Show a, Show t) => a -> NTree t -> String
gen_direct_children a (NTreeFork b _) = (show a)++" ->"++(show b) 
gen_direct_children a (NTreeEmpty) = ""

-- Function used to turn a tree map back into a tree
map_to_tree m = (map_to_tree_helper [NTreeEmpty] (reverse (sort m)))!!0

map_to_tree_helper c_accs [] = c_accs
map_to_tree_helper c_accs ((l,cs):ls) = 
   let cur_lev = map (create_node c_accs) cs in
      map_to_tree_helper cur_lev ls
  where
    create_node cs n = (NTreeFork n cs)

-- Function used to replace a "level" in a tree map
replace_level lev new_lev lmap =
  case (lookup lev lmap) of
    (Nothing)      ->  error "Level not found in map!"
    (Just old_lev) -> let lmap' = delete (lev,old_lev) lmap in
                          let lmap'' = (new_lev : lmap') in
                              lmap''

-- Function used to insert a new node at a given level
insert_item lev new_tree t =
 let lmap = level_map t in
     let (b,new_level) = add_node_to_level new_tree lev lmap in 
          if (b == True) then
	          let new_map = replace_level lev new_level lmap in
    	          map_to_tree new_map
		 else
			map_to_tree (new_level:lmap)

add_node_to_level node lev lmap =
   case (lookup lev lmap) of
      (Nothing)      -> (False,(lev,[node]))-- error "Level not found in tree!"
      (Just old_lev) -> (True,(lev,(node:old_lev)))


-- **********************************
-- Test Cases
-- **********************************
empty_tree = NTreeEmpty
node0= (NTreeFork "c = a + b" [empty_tree])
node1= (NTreeFork "d = a * 2" [empty_tree])
node2= (NTreeFork "c = 0" [empty_tree])
node3= (NTreeFork "d = 1" [empty_tree])

tree0 = node0

subtree1 = (NTreeFork "a = 0" [subsubtree1])
subsubtree1 = (NTreeFork "c = a + 20" [empty_tree])

subtree2 = (NTreeFork "b = 10" [subsubtree2])
subsubtree2 = (NTreeFork "d = b + a" [empty_tree])

tree1 = (NTreeFork "root" [subtree1, subtree2])

simple_tree = (NTreeFork "abc" [empty_tree])

test1 = insert_item 1 "xxx" simple_tree
test2 = insert_item 1 "yzy" test1
