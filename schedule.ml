type sem_status = Past | Present | Future
type grade = Sat | Unsat | Withdrawn | Incomplete | Letter of string 

type sem_id = Spring of int | Fall of int

type reqs = {
  temp: int;
}

type course = {
  name: string;
  mutable credits: int;
  mutable grade: grade;
  mutable degree: string;
  (* subject/category *)
}

type semester = {
  mutable id: sem_id;
  mutable courses: course list;
  mutable tot_credits: int;
  (*mutable sem_status: sem_status;*)
  mutable sem_gpa: float;
}

type schedule = {
  mutable desc: string;
  mutable semesters: semester list;
  mutable cumul_gpa: float;
  mutable exp_grad: int;
  mutable major: string;
  mutable sch_credits : int;
  mutable is_saved : bool;
}

exception UnknownCourse of string
exception UnknownSemester of string
exception UnknownGrade of string
exception DuplicateCourse of string
exception DuplicateSemester of string
exception InvalidCredits of string

let grade_map gr = 
  match gr with
  | Letter "A+" -> 4.3
  | Letter "A" -> 4.0
  | Letter "A-" -> 3.7
  | Letter "B+" -> 3.3
  | Letter "B" -> 3.0
  | Letter "B-" -> 2.7
  | Letter "C+" -> 2.3
  | Letter "C" -> 2.0
  | Letter "C-" -> 1.7
  | Letter "D+" -> 1.3
  | Letter "D" -> 1.0
  | Letter "D-" -> 0.7
  | Letter "F" -> 0.0
  | _ -> failwith "Impossible Failure"

let set_save_status sch bool =
  sch.is_saved <- bool

let gradify str =
  let str_upper = String.uppercase_ascii str in
  if Str.string_match (Str.regexp "^[A-D][\\+-]?$\\|^F$") str_upper 0 then
    Letter str_upper
  else
    match str_upper with
    | "INCOMPLETE" | "INC" -> Incomplete
    | "W" | "WITHDRAWN" -> Withdrawn
    | "SAT" | "S" -> Sat
    | "UNSAT" | "U" -> Unsat
    | _ -> raise (UnknownGrade str)

let gpa courses =
  let rec fold_credits courses acc =
    match courses with
    | [] -> acc
    | { credits = c; grade = g } :: t -> 
      if (grade_map g > 0.) then fold_credits t (acc + c)
      else fold_credits t acc
  in
  let rec fold_gps courses acc =
    match courses with
    | [] -> acc
    | { credits = c; grade = g } :: t -> 
      if (grade_map g >= 0.) then 
        fold_gps t (acc +. ((float_of_int c) *. grade_map g))
      else fold_gps t acc
  in
  (fold_gps courses 0.) /. (float_of_int (fold_credits courses 0))

let gpa_to_string gpa_float = 
  let gpa = string_of_float gpa_float in
  match String.length gpa with
  | 0 | 1 -> failwith "Impossible Case"
  | 2 -> gpa ^ "00"
  | 3 -> gpa ^ "0"
  | 4 -> gpa
  | _ -> Str.first_chars gpa 4

let get_credits sch = 
  sch.sch_credits

let calc_credits courses =
  let rec fold courses acc =
    match courses with
    | [] -> acc
    | { credits = c } :: t -> fold t (acc + c)
  in fold courses 0

let to_list sch =
  let rec fold sems acc = 
    match sems with
    | [] -> acc
    | {courses=x} :: t -> fold t (x @ acc)
  in
  fold sch.semesters []

let string_of_semid semid =
  match semid with
  | Spring yr -> "SP" ^ (string_of_int yr)
  | Fall yr -> "FA" ^ (string_of_int yr)

let string_of_grade gr =
  match gr with
  | Sat -> "Satisfactory"
  | Unsat -> "Unsatisfactory"
  | Withdrawn -> "Withdrawn"
  | Incomplete -> "Incomplete"
  | Letter l -> l

(** [sem_compare s1 s2] is a negative number if [s1] comes before [s2], 
    0 if theyre the same semester, and a positive number if [s1] comes after
    [s2]. *)
let sem_compare s1 s2 =
  match s1.id,s2.id with
  | Fall y1 , Fall y2
  | Spring y1 , Spring y2 -> Stdlib.compare y1 y2
  | Fall y1 , Spring y2 -> if y1 = y2 then 1 else Stdlib.compare y1 y2
  | Spring y1 , Fall y2 -> if y1 = y2 then -1 else Stdlib.compare y1 y2

let create_course name cred gr deg = 
  if cred < 0 then 
    raise (InvalidCredits "Credits have to be greater than or equal to zero.")
  else if not (Str.string_match 
                 (Str.regexp "^[A-Z][A-Z]+[0-9][0-9][0-9][0-9]$") name 0) then
    raise (UnknownCourse ("Invalid Course name - " ^ name))
  else
    {
      name = name;
      credits = cred;
      grade = gr;
      degree = deg;
    }

let rec get_course name courses = 
  match courses with 
  | [] -> raise (UnknownCourse name)
  | h :: t -> if h.name = name then h else get_course name t

let rec get_sem sch sems semid = 
  match sems with 
  | [] -> raise (UnknownSemester (string_of_semid semid))
  | h :: t -> if h.id = semid then h else get_sem sch t semid

let get_sems sch = 
  sch.semesters

let get_sem_courses sem =
  sem.courses 

let add_course sch c semid = 
  try
    let sem = List.find (fun sm -> sm.id = semid) sch.semesters in
    if List.mem c.name (List.map (fun c -> c.name) (to_list sch)) then
      raise (DuplicateCourse (c.name ^ " already in schedule."))
    else begin
      sem.courses <- (c :: sem.courses);
      sem.sem_gpa <- gpa sem.courses;
      sem.tot_credits <- sem.tot_credits + c.credits;
      sch.sch_credits <- sch.sch_credits + c.credits;
      sch.cumul_gpa <- gpa (to_list sch); 
      set_save_status sch false;
      sch
    end
  with
    Not_found -> raise (UnknownSemester (string_of_semid semid))

let rec get_sem_from_course sch sems course = 
  match sems with 
  | [] -> raise (UnknownCourse course.name)
  | h :: t -> if get_course course.name (to_list sch) = course then h else
      get_sem_from_course sch t course

let edit_course sch cname attr new_val =
  try
    let course = List.find (fun course -> course.name = cname) (to_list sch) in
    let sem = get_sem_from_course sch sch.semesters course in
    let old_creds = course.credits in
    match attr with
    | "credits" ->
      course.credits <- int_of_string new_val;
      let diff = int_of_string new_val - old_creds in 
      sem.tot_credits <- sem.tot_credits + diff;
      sch.sch_credits <- sch.sch_credits + diff;
      sem.sem_gpa <- gpa sem.courses;
      sch.cumul_gpa <- gpa (to_list sch); set_save_status sch false; sch
    | "grade" -> 
      course.grade <- gradify new_val;
      sem.sem_gpa <- gpa sem.courses;
      sch.cumul_gpa <- gpa (to_list sch); set_save_status sch false; sch
    | "degree" -> 
      course.degree <- new_val; set_save_status sch false; sch
    | _ -> raise (Failure "Invalid course attribute")
  with
    Not_found -> raise (UnknownCourse cname)

let remove_course sch cname =
  try
    let course = get_course cname (to_list sch) in
    let sem = get_sem_from_course sch sch.semesters course in
    sem.courses <- (List.filter (fun crs -> crs.name <> cname) sem.courses);
    sem.tot_credits <- sem.tot_credits - course.credits;
    sch.sch_credits <- sch.sch_credits - course.credits;
    sem.sem_gpa <- gpa sem.courses;
    sch.cumul_gpa <- gpa (to_list sch); 
    set_save_status sch false;
    sch
  with 
    Not_found -> raise (UnknownCourse cname)

let sem_ids sch =
  List.rev_map (fun sem -> sem.id) sch.semesters

let sem_ids_to_string sch =
  List.rev_map (fun sem -> string_of_semid sem.id) sch.semesters

let create_sem semid =
  {
    id = semid;
    courses = [];
    tot_credits = 0;
    sem_gpa = 0.
  }

let add_sem sch sem =
  if (List.mem sem.id (sem_ids sch)) then
    raise (DuplicateSemester (string_of_semid sem.id))
  else
    sch.semesters <- List.sort sem_compare (sem :: sch.semesters); 
  set_save_status sch false; sch

let remove_sem sch semid = 
  if (not (List.mem semid (sem_ids sch))) then
    raise (UnknownSemester (string_of_semid semid))
  else begin
    sch.semesters <- 
      (List.filter (fun sem -> sem.id <> semid) sch.semesters); 
    sch.cumul_gpa <- gpa (to_list sch);
    sch.sch_credits <- calc_credits (to_list sch);
    set_save_status sch false;
    sch end

let new_schedule =
  {
    desc = "";
    semesters = [];
    cumul_gpa = 0.;
    exp_grad = 0;
    major = "";
    sch_credits = 0;
    is_saved = true;
  }

let get_save_status sch = 
  sch.is_saved

let get_name sch =
  sch.desc

let edit_name sch nm =
  sch.desc <- nm;
  set_save_status sch false;
  sch

let set_init_name sch nm =
  sch.desc <- nm;
  set_save_status sch true;
  sch

let print_sem sem =
  print_string ": [ ";
  List.fold_right 
    (fun course _ -> print_string ((course.name) ^ ", ")) 
    sem.courses ();
  print_string (" ]\nSemester GPA: " ^ (gpa_to_string sem.sem_gpa));
  print_endline (" | Semester Credits: " ^ string_of_int sem.tot_credits);
  print_newline ()

let print_schedule sch =
  if sch.semesters = [] then 
    ANSITerminal.(
      print_string [red] 
        "No semesters in current schedule. Try running 'add <semester>'\n")
  else begin
    List.fold_left 
      (fun () sem -> print_string (string_of_semid sem.id); print_sem sem)
      () sch.semesters;
    print_endline ("Cumulative GPA: " ^ (gpa_to_string sch.cumul_gpa));
    print_endline ("Total Credits: " ^ (string_of_int sch.sch_credits))
  end


module HTML = struct

  (** [template] inputs data from a created HTML into a template. *)
  let template =
    let rec input_file acc chan = 
      try
        input_file (acc ^ ((input_line chan) ^ "\n")) chan
      with
        End_of_file -> acc
    in
    input_file "" (open_in "temp.html")

  (** [html_of_course c] returns a string that represents a course that can be
      converted into an HTML. *) 
  let html_of_course c =
    "\t\t\t\t<td>\n" ^ 
    "\t\t\t\t\t<h4><strong>" ^ c.name ^ "</strong></h4>\n" ^ 
    "\t\t\t\t\t<p>Credits: " ^ (string_of_int c.credits) ^ "</p>\n" ^
    "\t\t\t\t\t<p>Grade: " ^ (string_of_grade c.grade) ^ "</p>\n" ^ 
    "\t\t\t\t\t<p>Category: " ^ c.degree ^ "</p>\n" ^ 
    "\t\t\t\t</td>\n"

  (** [html_of_sem sem] returns a string that represents a semester that can be
      converted into an HTML. *) 
  let html_of_sem sem =
    match sem.courses with
    | [] -> "\t\t\t<tr><td class=\"noborder\"><h3>" ^ (string_of_semid sem.id) ^ 
            "</h3></td></tr>\n"
    | _ -> begin
        "\t\t\t<tr><td class=\"noborder\"><h3>" ^ (string_of_semid sem.id) ^ 
        "</h3>\n" ^
        "\t\t\t<p>Semester GPA: <strong>" ^ (gpa_to_string sem.sem_gpa) ^ 
        "</strong></p></td>\n" ^ 
        (List.fold_left (fun acc course -> acc ^ (html_of_course course)) 
           "" sem.courses) ^ 
        "\t\t\t</tr>\n" end

  (** [html_of_schedule sch] returns a string that represents a schedule that 
      can be converted into an HTML. *) 
  let html_of_schedule sch =
    match (get_sems sch) with
    | [] -> "<p>Schedule is empty!</p>\n"
    | _ -> begin
        "<h1><strong style=\"color:green;\">" ^ sch.desc ^ "</strong></h1>\n" ^ 
        "\t\t<h2>Cumulative GPA: <strong style=\"color:blue;\">" ^ 
        (gpa_to_string sch.cumul_gpa) ^ 
        "</strong></h2>\n" ^ 
        "\t\t<h2>Total Credits: <strong style=\"color:red;\">" ^ 
        (string_of_int sch.sch_credits) ^ "</strong></h2>\n" ^ 
        "\t\t<table>\n" ^ 
        (List.fold_left (fun acc sem -> acc ^ (html_of_sem sem)) 
           "" (get_sems sch)) ^ 
        "\t\t</table>\n" end

  (** [save filename text] creates a file named [filename] and puts [text]
      in it. *)
  let save filename text = 
    let chan = open_out filename in
    output_string chan text;
    close_out chan

  let export_schedule sch fl = 
    let reg = Str.regexp "<\\?sch>" in
    Str.replace_first reg (html_of_schedule sch) template |> save fl

end

module LoadJSON = struct

  module Yj = struct include Yojson.Basic.Util end

  (** [form_sem_id_helper sem lst] forms a semester id based on the string
      [sem] and the list [lst] which will be parsed to find a year. *)
  let form_sem_id_helper sem lst = 
    match List.rev lst with 
    | [] -> raise (UnknownSemester sem)
    | h :: t -> let yr = int_of_string h in 
      match sem with 
      | "Fall" -> Fall yr
      | "Spring" -> Spring yr
      | _ -> raise (UnknownSemester sem)

  (** [form_sem_id semid] determines if the semester in [semid] is referencing
      a fall or spring semester and calls a helper function to help form a 
      semester id. *)
  let form_sem_id semid = 
    if String.contains semid 'F' then let word = "Fall" in 
      let lst = String.split_on_char 'A' semid 
      in form_sem_id_helper word lst
    else 
      let word = "Spring" in 
      let lst = String.split_on_char 'P' semid
      in form_sem_id_helper word lst

  (** [form_grade grade] returns the grade represented by [grade]. *)
  let form_grade grade = 
    match grade with 
    | "Sat" -> Sat
    | "Unsat" -> Unsat
    | "Withdrawn" -> Withdrawn
    | "Incomplete" -> Incomplete
    | _ -> Letter grade

  (** [parse_course json] creates courses by parsing [json]. *)
  let parse_course json = {
    name = json |> Yj.member "name" |> Yj.to_string;
    credits = json |> Yj.member "course credits" |> Yj.to_int;
    grade = json |> Yj.member "grade" |> Yj.to_string |> form_grade;
    degree = json |> Yj.member "degree" |> Yj.to_string;
  }

  (** [get_semester json] creates semesters by parsing [json]. *)
  let get_semester json = 
    {
      id = json |> Yj.member "semester id" |> Yj.to_string |> form_sem_id;
      courses = json |> Yj.member "courses" |> Yj.to_list |> 
                List.map parse_course;
      tot_credits = json |> Yj.member "semester credits" |> Yj.to_int;
      sem_gpa = json |> Yj.member "semester gpa" |> Yj.to_float;
    }

  let parse_json fl = 
    let json = Yojson.Basic.from_file fl in
    {
      desc = json |> Yj.member "description" |> Yj.to_string;
      semesters = json |> Yj.member "semesters" |> Yj.to_list |> 
                  List.map get_semester;
      cumul_gpa = json |> Yj.member "cumul gpa" |> Yj.to_float;
      exp_grad = json |> Yj.member "expected grad year" |> Yj.to_int;
      major = json |> Yj.member "major" |> Yj.to_string;
      sch_credits = json |> Yj.member "sch credits" |> Yj.to_int;
      is_saved = true
    }

end

module SaveJSON = struct

  (** [json_of_course c] returns a string that represents a course that can be 
      converted into a JSON. *)
  let json_of_course c = 
    "\t\t\t\t{\n" ^
    "\t\t\t\t\t\"name\": \"" ^ c.name ^ "\",\n" ^
    "\t\t\t\t\t\"course credits\": " ^ (string_of_int c.credits) ^ ",\n" ^
    "\t\t\t\t\t\"grade\": \"" ^ (string_of_grade c.grade) ^ "\",\n" ^
    "\t\t\t\t\t\"degree\": \"" ^ c.degree ^ "\"\n" ^
    "\t\t\t\t},\n"

  (** [json_of_sem sem] returns a string that represents a semester that can be
      converted into a JSON. *)
  let json_of_sem sem = 
    let reg = Str.regexp "},\n$" in
    "\t\t{\n" ^
    "\t\t\t\"semester id\": \"" ^ (string_of_semid sem.id) ^ "\",\n" ^
    "\t\t\t\"semester credits\": " ^ (string_of_int sem.tot_credits) ^ ",\n" ^
    "\t\t\t\"semester gpa\": " ^ (gpa_to_string sem.sem_gpa) ^ ",\n" ^
    "\t\t\t\"courses\": [\n" ^ 
    (Str.replace_first reg "}\n" 
       (List.fold_left (fun acc course -> acc ^ (json_of_course course)) 
          "" (sem.courses))) ^
    "\t\t\t]\n\t\t},\n"

  (** [json_of_schedule sch] returns a string that can be converted into a JSON
      file that can be saved. *)
  let json_of_schedule sch = 
    let reg = Str.regexp "},\n$" in
    "{\n" ^
    "\t\"description\": \"" ^ sch.desc ^ "\",\n" ^
    "\t\"cumul gpa\": "  ^ (gpa_to_string sch.cumul_gpa) ^ ",\n" ^
    "\t\"sch credits\": "  ^ (string_of_int sch.sch_credits) ^ ",\n" ^
    "\t\"expected grad year\": " ^ (string_of_int sch.exp_grad) ^ ",\n" ^
    "\t\"major\": \"" ^ sch.major ^ "\",\n" ^
    "\t\"semesters\": [\n" ^ 
    (Str.replace_first reg "}\n" 
       (List.fold_left (fun acc sem -> acc ^ (json_of_sem sem)) 
          "" (sch.semesters))) ^
    "\t]\n}\n"

  let save_schedule sch fl =
    let chan = open_out fl in
    output_string chan (json_of_schedule sch);
    set_save_status sch true;
    close_out chan

end