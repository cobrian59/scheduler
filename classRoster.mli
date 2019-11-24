open Schedule

(** Exception to be raised with any problems getting course information from
    Class Roster. *)
exception InvalidURL

(** [get_course_creds nm sem] is the number of credits
    this course is worth during semester [sem] as indicated by class roster.
    Raises: [UnkownCourse nm] if course name isn not a valid course. 
            [InvalidURL] if information can't be obtained from class roster
    for any reason.*)
val get_course_creds : string -> sem_id -> int

(** [string_of_url url] is the source HTML at URL [url].
    Raises: [InvalidURL] if [url] is not a valid URL or ocurl cannot
    get data from it for any reason (like no internet) *)
val string_of_url : string -> string -> string

(*
  FOR SPRINT 2
(** [valid_course name sem credits] is *)
val valid_course : string -> sem_id -> int -> bool *)