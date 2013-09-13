(** Time *)

open Printf
open ExtLib

open Prelude

type t = float

let get = Unix.gettimeofday
let now = Unix.gettimeofday

let fast_to_string =
  (* "%04u-%02u-%02uT%02u:%02u:%02u%s" *)
  let template = "2013-__-__T__:__:__" in
  let template_z = template ^ "Z" in
  let digit n = Char.unsafe_chr (Char.code '0' + n) in
  let put s ofs n =
    String.unsafe_set s ofs (digit (n / 10));
    String.unsafe_set s (ofs+1) (digit (n mod 10))
  in
  fun ~gmt f ->
    let open Unix in
    let t = (if gmt then gmtime else localtime) f in
    let s = String.copy (if gmt then template_z else template) in
    let year = 1900 + t.tm_year in
    if year <> 2013 then
    begin
      if year >= 2010 && year < 2020 then
        String.unsafe_set s 3 (digit (year mod 10))
      else
        String.unsafe_blit (string_of_int year) 0 s 0 4;
    end;
    put s 5 (t.tm_mon+1);
    put s 8 t.tm_mday;
    put s 11 t.tm_hour;
    put s 14 t.tm_min;
    put s 17 t.tm_sec;
    s

let to_string ?(gmt=false) ?(ms=false) f =
  match ms with
  | false -> fast_to_string ~gmt f
  | true ->
    let t = (if gmt then Unix.gmtime else Unix.localtime) f in
    let sec = sprintf "%07.4f" (mod_float f 60.) in
    sprintf "%04u-%02u-%02uT%02u:%02u:%s%s"
      (1900 + t.Unix.tm_year) (t.Unix.tm_mon+1) t.Unix.tm_mday t.Unix.tm_hour t.Unix.tm_min sec (if gmt then "Z" else "")

(** @see <http://www.w3.org/TR/NOTE-datetime> W3C Datetime *)
let gmt_string = to_string ~gmt:true ~ms:false
let gmt_string_ms = to_string ~gmt:true ~ms:true

(** unix timestamp to RFC-2822 date
    Example: Tue, 15 Nov 1994 12:45:26 GMT *)
let to_rfc2822 secs =
  let module U = Unix in
  let t = U.gmtime secs in
  let wdays = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
  let mons = [|"Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun"; "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec"|] in
  let wday = wdays.(t.U.tm_wday mod 7) in
  let mon = mons.(t.U.tm_mon mod 12) in
  sprintf "%s, %02u %s %04u %02u:%02u:%02u GMT" wday t.U.tm_mday mon (1900 + t.U.tm_year) t.U.tm_hour t.U.tm_min t.U.tm_sec

let duration_str t =
  let factors = [60; 60; 24; 30; 12;] in
  let names = ["secs"; "min"; "hours"; "days"; "months";] in
  let rec loop t acc = function
  | [] -> List.rev acc
  | n::tl -> loop (t/n) (t mod n :: acc) tl
  in
  if t < 1. then sprintf "%.4f secs" t
  else if t < 10. then sprintf "%.2f secs" t
  else 
  loop (int_of_float t) [] factors >> List.combine names >> List.rev >> 
  List.dropwhile (fun (_,x) -> x = 0) >>
  List.map (fun (n,x) -> sprintf "%u %s" x n) >> String.concat " "

(* 1m10s *)
let compact_duration t =
  let factors = [60; 60; 24; ] in
  let names = ["s"; "m"; "h"; "d"; ] in
  let rec loop t acc = function
  | [] -> List.rev (t::acc)
  | n::tl -> loop (t/n) (t mod n :: acc) tl
  in
  if t < 1. then sprintf "%.2fs" t
  else if t < 10. then sprintf "%.1fs" t
  else 
  loop (int_of_float t) [] factors >> List.combine names >>
  List.dropwhile (fun (_,x) -> x = 0) >>
  List.rev >>
  List.dropwhile (fun (_,x) -> x = 0) >>
  List.map (fun (n,x) -> sprintf "%u%s" x n) >> String.concat ""

(** parse compact_duration representation (except for fractional seconds) *)
let of_compact_duration s = Devkit_ragel.parse_compact_duration s

let minutes x = float & 60 * x
let hours x = minutes & 60 * x
let days x = hours & 24 * x
let seconds x = float x

