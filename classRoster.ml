open Schedule

exception InvalidURL

(* Returns body of URL as string *)
let string_of_url url nm = 
  try
    let connection = Curl.init () and result = ref "" in
    Curl.set_writefunction connection
      (fun x -> result := !result ^ x; String.length x);
    Curl.set_url connection url;
    Curl.perform connection;
    Curl.global_cleanup ();
    !result
  with
    _ -> raise InvalidURL

(** [course_html name sem] is the html body from the class roster site for 
    course [name] during semester with id [sem].
    Rasies: [InvalidURL] if data cannot be obtained for any reason. *)
let course_html name sem =
  let c_num = Str.last_chars name 4 in
  let c_dep = Str.first_chars name ((String.length name) - 4) in
  let url = "https://classes.cornell.edu/browse/roster/" ^ 
            (string_of_semid sem) ^ "/class/" ^ c_dep ^ "/" ^ 
            c_num in
  string_of_url url name

(** [parse_credits] is the number of credits for the course whose class roster
    webpage is stored in [html].
    Raises: [InvalidURL] if [html] doesn't contain this information. *)
let parse_credits html =
  let reg = Str.regexp_string "<span class=\"credit-val\">" in
  try
    int_of_string (String.sub html ((Str.search_forward reg html 0) + 25) 1)
  with
    _ -> raise InvalidURL

let get_course_creds name sem =
  let n_upper = String.uppercase_ascii name in
  let reg = Str.regexp "^[A-Z][A-Z]+[0-9][0-9][0-9][0-9]$" in
  if (Str.string_match reg n_upper 0) then
    parse_credits (course_html n_upper sem)
  else
    raise (UnknownCourse name)

(*
  FOR SPRINT 2
let valid_course name sem credits =
  try
    if (get_course_creds name sem = credits) then true
    else raise InvalidCredits;
  with
    _ -> raise (UnknownCourse name)*)