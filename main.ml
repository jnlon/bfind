module U = Unix ;;
module F = Filename ;;
module P = Printf ;;

(* Read file entries from dirhandle, but remove '.' and '..' *)
let rec readdir_no_dot dirhandle = 
  let entry = U.readdir dirhandle in
  match entry with 
      "." -> readdir_no_dot dirhandle
    | ".." -> readdir_no_dot dirhandle
    | _ -> entry
;;

(* Remove suffix suf from end of string *)
let chop_suffix str suff = 
  if ((String.length str) != 1 && (F.check_suffix str suff))
  then F.chop_suffix str suff
  else str
;;

(* Ask if file at path is of type Unix.file_kind *)
let is_file_type (path : string) (kind : U.file_kind) = 
  let open Unix in
  try
    U.access path [U.R_OK;U.F_OK]; 
    (U.stat path).st_kind = kind 
  with _ -> false
;;

let is_directory path = is_file_type path U.S_DIR;;

let show_help () = 
  prerr_endline "Usage: bfind [file]..."
;;

(* Return a string list of all entries at dirhandle *)
let list_dir_entries dirhandle = 
  let rec make_list lst =
    try
      make_list ((readdir_no_dot dirhandle) :: lst)
    with End_of_file -> lst
  in
  make_list []
;;

(* Find a directory "depth" levels down, and print what's there. Returns true
 * if there more subdirectories at the level "depth", indicating that we can go
 * deeper *)
let rec bfind (path : string) (depth: int) : bool =
  try
    let open List in
    let dirhandle = U.opendir path in
    let entries_here = (list_dir_entries dirhandle) in
    let paths = map (Filename.concat path) entries_here in
    let directories = filter is_directory paths in

    U.closedir dirhandle;

    (* We've reached our target depth level *)
    if depth = 0 then begin
      iter print_endline paths;
      if (length directories) = 0 then false
      else true
    end
    else begin 
      let dig newpath = bfind newpath (depth - 1) 
      in
      let dig_results = (map dig directories) 
      in
      try  (* If any of dig_results are true, we can still keep digging, so return true *)
        find (fun p -> p = true) dig_results 
      with Not_found -> false; 
    end
  with U.Unix_error (e,func,arg) -> false; (* Error opening a directory *)
;;

(* Run bfind for every valid directory path in argv *)
let rec process_argv argv = 
  (* Successively call bfind with increasing depth until it returns false *)
  let rec find_at_depth path depth = 
    if (bfind path depth)  
    then find_at_depth path (depth + 1)
    else ()
  in
  match argv with 
    this_arg :: rest_argv -> 
      begin try 
          let start_path = chop_suffix this_arg F.dir_sep in
          Unix.access start_path [U.R_OK;U.F_OK]; (* Does directory file exist? *)
          print_endline start_path;
          find_at_depth start_path 0;
          process_argv rest_argv
        with U.Unix_error (e,func,arg) -> 
          P.fprintf stderr "'%s' on '%s': %s \n" func arg (U.error_message e);
          show_help ();
          process_argv rest_argv 
      end
    | [] -> ()

(* Exit if there are no arguments, otherwise, process argv *)
let rec main argc argv = 
  if (argc <= 1) then 
    (show_help (); exit 1)
  else 
    process_argv (List.tl argv)
;;

main (Array.length Sys.argv) (Array.to_list Sys.argv)
