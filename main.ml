(* A 'past' is a tuple with a file path and a stat value *)
type past_t = 
    Maybe of (string * Unix.stats)
  | Nothing 
;;

let dir_types = [Unix.S_DIR] ;;

(* Read file entries from dirhandle, but remove '.' and '..' *)
let rec readdir_no_dot dirhandle = 
  let entry = Unix.readdir dirhandle in
  match entry with 
      "." -> readdir_no_dot dirhandle
    | ".." -> readdir_no_dot dirhandle
    | _ -> entry
;;

(* Remove suffix suf from end of string *)
let chop_suffix str suff = 
  if (str != "/") && (Filename.check_suffix str suff)
  then Filename.chop_suffix str suff
  else str
;;

let show_help () = 
  prerr_endline "Usage: bfind [file]..."
;;

let path_join dir path = 
  (chop_suffix dir Filename.dir_sep) ^ Filename.dir_sep ^ path
;;

(* Create a list of 'pasts' from every entry in the directory at 'path' *)
let read_pasts_from_path path : past_t list = 
  let dh = Unix.opendir path in
  let rec read_files pasts_l = 
    try
      let newpath = path_join path (readdir_no_dot dh) in
      try
        let stat = Unix.lstat newpath in
        read_files (Maybe (newpath, stat) :: pasts_l)
      with Unix.Unix_error(_,_,_) -> read_files pasts_l
    with End_of_file -> pasts_l
  in
  let pasts = read_files [] in
  Unix.closedir dh;
  pasts
;;

let past_is_dir (past : past_t) = 
  let open Unix in
  match past with
    | Maybe (_,stat) -> List.memq stat.st_kind dir_types
    | Nothing -> false
;;

let print_past = function
    | Maybe (path,_) -> print_endline path
    | Nothing -> ()
;;

let rec retrieve_and_print_subdir_pasts = function
    | Maybe (path,stat) -> begin 
        try
          let pasts = (read_pasts_from_path path) in
          List.iter print_past pasts;
          pasts
        with Unix.Unix_error(err,func,desc) ->
          (Printf.eprintf "%s: %s: %s\n" func (Unix.error_message err) desc; [])
        end
    | Nothing -> []
;;

(* dir_pasts is a list of path/stat tuples for _every_ directory at this level
 * in the filesystem (relative to the starting directory)  *)
let rec bfind (dir_pasts : past_t list) =

  (* List of every past immediately under dir_pasts *)
  let all_sub_pasts =           
    List.concat @@ List.map retrieve_and_print_subdir_pasts dir_pasts 
  in 
  (* Filter out non-directories *)
  let new_subdir_pasts =        
    List.filter past_is_dir all_sub_pasts  
  in  

  (* Anymore subdirectories? *)
  if new_subdir_pasts = [] 
  then ()
  (* Recurse into the the next level in filesystem *)
  else bfind new_subdir_pasts 
;;

let rec process_path filepath =
  print_endline filepath;
  bfind 
    begin try
      [Maybe (filepath,Unix.stat filepath)]
    with _ -> [Nothing] end
;;

(* Exit if there are no arguments, otherwise, process argv *)
let rec main argc argv = 
  if (argc <= 1) then 
    (show_help (); exit 1)
  else 
    List.iter process_path (List.tl argv)
;;

main (Array.length Sys.argv) (Array.to_list Sys.argv)
