; SOFT (Second-Order Functions and Theorems) -- Implementation
;
; Copyright (C) 2015-2017 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "SOFT")

(include-book "kestrel/utilities/defchoose-queries" :dir :system)
(include-book "kestrel/utilities/defun-sk-queries" :dir :system)
(include-book "kestrel/utilities/er-soft-plus" :dir :system)
(include-book "kestrel/utilities/event-forms" :dir :system)
(include-book "kestrel/utilities/keyword-value-lists" :dir :system)
(include-book "kestrel/utilities/symbol-symbol-alists" :dir :system)
(include-book "kestrel/utilities/user-interface" :dir :system)
(include-book "std/alists/alist-equiv" :dir :system)
(include-book "std/util/defines" :dir :system)

(local (xdoc::set-default-parents soft-implementation))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define inputs-have-verbose-t-p ((inputs true-listp))
  :returns (yes/no booleanp)
  :short "Check if a list of inputs (to a SOFT macro) includes @(':verbose t')."
  :long
  "<p>
   The list is examined from right to left,
   two elements at a time,
   so long as the first of the two elements if a keyword.
   If @(':verbose t') is found, @('t') is returned.
   If @(':verbose x') is found and @('x') is not @('t'), @('nil') is returned.
   If there are no more keyword-value pairs, @('nil') is returned.
   </p>"
  (inputs-have-verbose-t-p-aux (rev inputs))

  :prepwork
  ((define inputs-have-verbose-t-p-aux ((rev-inputs true-listp))
     :returns (yes/no booleanp)
     (if (or (endp rev-inputs)
             (endp (cdr rev-inputs)))
         nil
       (b* ((value? (car rev-inputs))
            (keyword? (cadr rev-inputs)))
         (if (keywordp keyword?)
             (if (eq keyword? :verbose)
                 (eq value? t)
               (inputs-have-verbose-t-p-aux (cddr rev-inputs)))
           nil))))))

(define *-listp (stars)
  :returns (yes/no booleanp)
  :short "Recognize @('nil')-terminated lists of @('*')s."
  :long
  "<p>
   These lists are used to indicate the number of arity of function variables
   in @(tsee defunvar).
   </p>
   <p>
   Any @('*') symbol (i.e. in any package) is allowed.
   Normally, the @('*') in the current package should be used
   (without package qualifier),
   which is often the one from the main Lisp package,
   which other packages generally import.
   </p>"
  (if (atom stars)
      (null stars)
    (and (symbolp (car stars))
         (equal (symbol-name (car stars)) "*")
         (*-listp (cdr stars)))))

(defsection function-variables-table
  :short "Table of function variables."
  :long
  "<p>
   The names of declared function variables
   are stored as keys in a @(tsee table).
   No values are associated to these keys, so the table is essentially a set.
   Note that the arity of a function variable
   can be retrieved from the @(tsee world).
   </p>"

  (table function-variables nil nil :guard (and (symbolp acl2::key)
                                                (null acl2::val))))

(define funvarp (funvar (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize names of function variables."
  :long
  "<p>
   These are symbols that name declared function variables,
   i.e. that are in the table of function variables.
   </p>"
  (let ((table (table-alist 'function-variables wrld)))
    (and (symbolp funvar)
         (not (null (assoc-eq funvar table))))))

(define defunvar-fn ((inputs true-listp)
                     (call pseudo-event-formp "Call to @(tsee defunvar).")
                     (ctx "Context for errors.")
                     state)
  :returns (mv (erp "@(tsee booleanp) flag of the
                     <see topic='@(url acl2::error-triple)'>error
                     triple</see>.")
               (event (or (pseudo-event-formp event) (null event)))
               state)
  :verify-guards nil
  :short "Validate the inputs to @(tsee defunvar)
          and generate the event form to submit."
  :long
  "<p>
   Similary to @(tsee *-listp),
   any @('*') and @('=>') symbol (i.e. in any package) is allowed.
   </p>"
  (b* ((wrld (w state))
       ((unless (>= (len inputs) 4))
        (er-soft+ ctx t nil
                  "At least four inputs must be supplied, not ~n0."
                  (len inputs)))
       (funvar (first inputs))
       (arguments (second inputs))
       (arrow (third inputs))
       (result (fourth inputs))
       (options (nthcdr 4 inputs))
       ((unless (symbolp funvar))
        (er-soft+ ctx t nil
                  "The first input must be a symbol, but ~x0 is not."
                  funvar))
       ((unless (*-listp arguments))
        (er-soft+ ctx t nil
                  "The second input must be a list (* ... *), but ~x0 is not."
                  arguments))
       ((unless (and (symbolp arrow)
                     (equal (symbol-name arrow) "=>")))
        (er-soft+ ctx t nil
                  "The third input must be =>, but ~x0 is not."
                  arrow))
       ((unless (and (symbolp result)
                     (equal (symbol-name result) "*")))
        (er-soft+ ctx t nil
                  "The fourth input must be *, but ~x0 is not."
                  result))
       ((unless (or (null options)
                    (and (= (len options) 2)
                         (eq (car options) :verbose))))
        (er-soft+ ctx t nil
                  "After the * input there may be at most one :VERBOSE option, ~
                   but instead ~x0 was supplied."
                  options))
       (verbose (if options
                    (cadr options)
                  nil))
       ((unless (booleanp verbose))
        (er-soft+ ctx t nil
                  "The :VERBOSE input must be T or NIL, but ~x0 is not."
                  verbose))
       ((when (funvarp funvar wrld))
        (b* ((arity (arity funvar wrld)))
          (if (= arity (len arguments))
              (prog2$ (cw "~%The call ~x0 is redundant.~%" call)
                      (value `(value-triple :invisible)))
            (er-soft+ ctx t nil "A function variable ~x0 with arity ~x1 ~
                                 already exists.~%" funvar arity))))
       (event `(progn
                 (defstub ,funvar ,arguments ,arrow ,result)
                 (table function-variables ',funvar nil)
                 (value-triple ',funvar))))
    (value event)))

(defsection defunvar-implementation
  :short "Implementation of @(tsee defunvar)."
  :long
  "@(def defunvar)
   @(def acl2::defunvar)"

  (defmacro defunvar (&whole call &rest inputs)
    (control-screen-output
     (inputs-have-verbose-t-p inputs)
     `(make-event (defunvar-fn
                    ',inputs
                    ',call
                    (cons 'defunvar ',(if (consp inputs) (car inputs) nil))
                    state)
                  :on-behalf-of :quiet)))

  (defmacro acl2::defunvar (&rest inputs)
    `(defunvar ,@inputs)))

(defsection show-defunvar
  :short "Show the event form generated by @(tsee defunvar),
          without submitting them."
  :long
  "@(def show-defunvar)
   @(def acl2::show-defunvar)"

  (defmacro show-defunvar (&whole call
                                  funvar arguments arrow result &key verbose)
    `(defunvar-fn
       ',funvar
       ',arguments
       ',arrow
       ',result
       ',verbose
       ',call
       (cons 'defunvar ',funvar)
       state))

  (defmacro acl2::show-defunvar (&rest args)
    `(show-defunvar ,@args)))

(define funvar-listp (funvars (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize @('nil')-terminated lists of function variables."
  (if (atom funvars)
      (null funvars)
    (and (funvarp (car funvars) wrld)
         (funvar-listp (cdr funvars) wrld))))

(define funvar-setp (funvars (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize non-empty sets of function variables."
  :long
  "<p>
   Here &lsquo;set&rsquo; means a list without repetitions.
   </p>"
  (and (funvar-listp funvars wrld)
       funvars
       (no-duplicatesp funvars)))

(define sofun-kindp (kind)
  :returns (yes/no booleanp)
  :short "Recognize symbols that denote
          the kinds of second-order functions supported by SOFT."
  :long
  "<p>
   Following the terminology used in the Workshop paper,
   in the implementation we use:
   </p>
   <ul>
     <li>
     @('plain') for second-order functions introduced via @(tsee defun2).
     </li>
     <li>
     @('choice') for second-order functions introduced via @(tsee defchoose2).
     </li>
     <li>
     @('quant') for second-order functions introduced via @(tsee defun-sk2).
     </li>
   </ul>"
  (or (eq kind 'plain)
      (eq kind 'choice)
      (eq kind 'quant)))

(define sofun-infop (info (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize the information associated to second-order function names
          in the table of second-order functions."
  :long
  "<p>
   This records the function's kind and function parameters.
   </p>"
  (and (true-listp info)
       (= (len info) 2)
       (sofun-kindp (first info))
       (funvar-setp (second info) wrld)))

(defsection second-order-functions-table
  :short "Table of second-order functions."
  :long
  "<p>
   The names of declared second-order functions
   are stored as keys in a @(see table),
   associated with kind and function parameters.
   </p>"

  (table second-order-functions nil nil
    :guard (and (symbolp acl2::key)
                (sofun-infop acl2::val world))))

(define sofunp (sofun (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize names of second-order functions."
  (let ((table (table-alist 'second-order-functions wrld)))
    (and (symbolp sofun)
         (not (null (assoc-eq sofun table))))))

(define sofun-kind ((sofun (sofunp sofun wrld)) (wrld plist-worldp))
  :returns (kind "A @(tsee sofun-kindp).")
  :verify-guards nil
  :short "Kind of a second-order function recorded in the table."
  (let ((table (table-alist 'second-order-functions wrld)))
    (first (cdr (assoc-eq sofun table)))))

(define plain-sofunp (sofun (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize plain second-order functions."
  (and (sofunp sofun wrld)
       (eq (sofun-kind sofun wrld) 'plain)))

(define choice-sofunp (sofun (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize choice second-order functions."
  (and (sofunp sofun wrld)
       (eq (sofun-kind sofun wrld) 'choice)))

(define quant-sofunp (sofun (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize quantifier second-order functions."
  (and (sofunp sofun wrld)
       (eq (sofun-kind sofun wrld) 'quant)))

(define sofun-fparams ((sofun (sofunp sofun wrld)) (wrld plist-worldp))
  :returns (fparams "A @(tsee funvar-setp).")
  :verify-guards nil
  :short "Function parameter of a second-order function recorded in the table."
  (let ((table (table-alist 'second-order-functions wrld)))
    (second (cdr (assoc-eq sofun table)))))

(defines funvars-of-term/terms
  :verify-guards nil
  :short "Function variables referenced by terms."
  :long
  "<p>
   A term may reference a function variable directly
   (when the function variable occurs in the term)
   or indirectly
   (when the function variable
   is a parameter of a second-order function that occurs in the term).
   </p>
   <p>
   Note that, in the following code,
   if @('(sofunp fn wrld)') is @('nil'),
   then @('fn') is a first-order function,
   which references no function variables.
   </p>
   <p>
   The returned list may contain duplicates.
   </p>
   @(def funvars-of-term)
   @(def funvars-of-terms)"

  (define funvars-of-term ((term pseudo-termp) (wrld plist-worldp))
    :returns (funvars "A @(tsee funvar-listp).")
    (if (or (variablep term)
            (quotep term))
        nil
      (let* ((fn (fn-symb term))
             (fn-vars
              (if (flambdap fn)
                  (funvars-of-term (lambda-body fn) wrld)
                (if (funvarp fn wrld)
                    (list fn)
                  (if (sofunp fn wrld)
                      (sofun-fparams fn wrld)
                    nil)))))
        (append fn-vars (funvars-of-terms (fargs term) wrld)))))

  (define funvars-of-terms ((terms pseudo-term-listp) (wrld plist-worldp))
    :returns (funvars "A @(tsee funvar-listp).")
    (if (endp terms)
        nil
      (append (funvars-of-term (car terms) wrld)
              (funvars-of-terms (cdr terms) wrld)))))

(define funvars-of-defun ((fun symbolp) (wrld plist-worldp))
  :returns (funvars "A @(tsee funvar-listp).")
  :mode :program
  :short "Function variables referenced
          by a plain or quantifier second-order function
          or by an instance of it."
  :long
  "<p>
   Plain and quantifier second-order functions and their instances
   may reference function variables
   in their defining bodies,
   in their measures (absent in quantifier functions),
   and in their guards
   (which are introduced via @(':witness-dcls') for quantifier functions).
   For now recursive second-order functions (which are all plain)
   and their instances
   are only allowed to use @(tsee o<) as their well-founded relation,
   and so plain second-order functions and their instances
   may not reference function variables in their well-founded relations.
   </p>
   <p>
   Note that if the function is recursive,
   the variable @('measure') in the following code is @('nil'),
   and @(tsee funvars-of-term) applied to that yields @('nil').
   </p>
   <p>
   The returned list may contain duplicates.
   </p>
   <p>
   Note that (an instance of) a quantifier function
   is ultimately introduced by a @(tsee defun) primitive event,
   so the @('defun') suffix in the name of @('funvars-of-defun') is appropriate.
   </p>"
  (let* ((body (ubody fun wrld))
         (measure (if (recursivep fun nil wrld)
                      (measure fun wrld)
                    nil))
         (guard (guard fun nil wrld))
         (body-funvars (funvars-of-term body wrld))
         (measure-funvars (funvars-of-term measure wrld))
         (guard-funvars (funvars-of-term guard wrld)))
    (append body-funvars
            measure-funvars
            guard-funvars)))

(define funvars-of-defchoose ((fun symbolp) (wrld plist-worldp))
  :returns (funvars "A @(tsee funvar-listp).")
  :mode :program
  :short "Function variables referenced
          by a choice second-order function
          or by an instance of it."
  :long
  "<p>
   Choice second-order functions and their instances
   may reference function variables in their defining bodies.
   </p>
   <p>
   The returned list may contain duplicates.
   </p>"
  (funvars-of-term (defchoose-body fun wrld) wrld))

(define funvars-of-defthm ((thm symbolp) (wrld plist-worldp))
  :returns (funvars "A @(tsee funvar-listp).")
  :mode :program
  :short "Function variables referenced
          by a second-order theorem or by an instance of it."
  :long
  "<p>
   Second-order theorems and their instances
   may reference function variables in their formulas.
   </p>
   <p>
   The returned list may contain duplicates.
   </p>"
  (funvars-of-term (formula thm nil wrld) wrld))

(define check-fparams-dependency ((fun symbolp)
                                  (kind sofun-kindp)
                                  (fparams (or (funvar-setp fparams wrld)
                                               (null fparams)))
                                  (wrld plist-worldp))
  :returns (yes/no "A @(tsee booleanp).")
  :mode :program
  :short "Check if a second-order function, or an instance of it,
          depends exactly on a set of given function parameters."
  :long
  "<p>
   When a second-order function, or an instance thereof, is introduced,
   the submitted event form first introduces the function,
   and then checks whether it depends exactly on its function parameters.
   The following code performs that check.
   </p>
   <p>
   The argument @('fparams') is @('nil') when the function in question
   is first-order (instance of a second-order function);
   in this case, the function must depend on no function variables.
   Otherwise, @('fparams') is not @('nil')
   and the function in question is second-order.
   </p>
   <p>
   The @('kind') argument is the kind of @('fun') if second-order,
   otherwise it is the kind of the second-order function
   of which @('fun') is an instance.
   </p>"
  (let ((funvars (case kind
                   (plain (funvars-of-defun fun wrld))
                   (choice (funvars-of-defchoose fun wrld))
                   (quant (funvars-of-defun fun wrld)))))
    (cond ((set-equiv funvars fparams) t)
          (fparams
           (raise "~x0 must depend on exactly its function parameters ~x1, ~
                   but depends on ~x2 instead.~%"
                  fun fparams funvars))
          (t
           (raise "~x0 must depend on no function parameters, ~
                   but depends on ~x1 instead.~%"
                  fun funvars)))))

(define check-wfrel-o< ((fun symbolp) (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Check if a recursive second-order function, or an instance of it,
          uses @(tsee o<) as well-founded relation."
  :long
  "<p>
   When a recursive second-order function, or an instance thereof,
   is introduced,
   the submitted event form first introduces the function,
   and then checks whether its well-founded relation is @(tsee o<).
   The following code performs this check.
   </p>"
  (if (recursivep fun nil wrld)
      (let ((wfrel (well-founded-relation fun wrld)))
        (or (eq wfrel 'o<)
            (raise "~x0 must use O< as well-founded relation, not ~x1.~%"
                   fun wfrel)))
    t))

(define check-qrewrite-rule-funvars ((fun symbolp) (wrld plist-worldp))
  :returns (yes/no "A @(tsee booleanp).")
  :mode :program
  :short "Check if the rewrite rule of a quantifier second-order function,
          or of an instance of it,
          depends exactly on a set of given function variables."
  :long
  "<p>
   When a quantifier second-order function, or an instance thereof,
   is introduced,
   the submitted event form first introduces the function,
   and then checks whether its rewrite rule depends
   exactly on given function variables.
   The following code performs this check.
   </p>
   <p>
   This check is relevant when the rewrite rule is a custom one.
   Otherwise, it is a redundant check.
   </p>"
  (let* ((rule-name (defun-sk-info->rewrite-name (defun-sk-check fun wrld)))
         (rule-body (formula rule-name nil wrld))
         (fun-body (ubody fun wrld)))
    (or (set-equiv (funvars-of-term rule-body wrld)
                   (funvars-of-term fun-body wrld))
        (raise "The custom rewrite rule ~x0 must have ~
                the same function variables as the function body ~x1.~%"
               rule-body fun-body))))

(define defun2-fn (sofun fparams rest (wrld plist-worldp))
  :returns (event (or (pseudo-event-formp event) (null event)))
  :verify-guards nil
  :short "Validate some of the inputs to @(tsee defun2)
          and generate the event form to submit."
  :long
  "<p>
   We directly check the name and function parameters,
   but rely on @(tsee defun) to check the rest of the form.
   After submitting the @(tsee defun) form,
   we check that the function parameters are
   all and only the function variables that the function depends on,
   and, if the function is recursive,
   that the well-founded relation is @(tsee o<).
   </p>"
  (b* (((unless (symbolp sofun))
        (raise "~x0 must be a name." sofun))
       ((unless (funvar-setp fparams wrld))
        (raise "~x0 must be a non-empty list of function variables ~
                without duplicates."
               fparams))
       (info (list 'plain fparams)))
    `(progn
       (defun ,sofun ,@rest)
       (table second-order-functions ',sofun ',info)
       (value-triple (and (check-wfrel-o< ',sofun (w state))
                          (check-fparams-dependency ',sofun
                                                    'plain
                                                    ',fparams
                                                    (w state)))))))

(defsection defun2-implementation
  :short "Implementation of @(tsee defun2)."
  :long
  "@(def defun2)
   @(def acl2::defun2)"

  (defmacro defun2 (sofun fparams &rest rest)
    `(make-event (defun2-fn ',sofun ',fparams ',rest (w state))))

  (defmacro acl2::defun2 (&rest args)
    `(defun2 ,@args)))

(defsection show-defun2
  :short "Show the event form generated by @(tsee defun2),
          without submitting them."
  :long
  "@(def show-defun2)
   @(def acl2::show-defun2)"

  (defmacro show-defun2 (sofun fparams &rest rest)
    `(defun2-fn ',sofun ',fparams ',rest (w state)))

  (defmacro acl2::show-defun2 (&rest args)
    `(show-defun2 ,@args)))

(define defchoose2-fn
  (sofun bvars fparams params body options (wrld plist-worldp))
  :returns (event (or (pseudo-event-formp event) (null event)))
  :verify-guards nil
  :short "Validate some of the inputs to @(tsee defchoose2)
          and generate the event form to submit."
  :long
  "<p>
   We directly check the name, bound variables, and function parameters,
   but rely on @(tsee defchoose) to check the rest of the form.
   After submitting the @(tsee defchoose) form,
   we check that the function parameters are
   all and only the function variables that the function depends on.
   </p>"
  (b* (((unless (symbolp sofun))
        (raise "~x0 must be a name." sofun))
       ((unless (or (symbolp bvars)
                    (symbol-listp bvars)))
        (raise "~x0 must be one or more bound variables." bvars))
       ((unless (funvar-setp fparams wrld))
        (raise "~x0 must be a non-empty list of function variables ~
                without duplicates."
               fparams))
       (info (list 'choice fparams)))
    `(progn
       (defchoose ,sofun ,bvars ,params ,body ,@options)
       (table second-order-functions ',sofun ',info)
       (value-triple (check-fparams-dependency ',sofun
                                               'choice
                                               ',fparams
                                               (w state))))))

(defsection defchoose2-implementation
  :short "Implementation of @(tsee defchoose2)."
  :long
  "@(def defchoose2)
   @(def acl2::defchoose2)"

  (defmacro defchoose2 (sofun bvars fparams vars body &rest options)
  `(make-event
    (defchoose2-fn
      ',sofun ',bvars ',fparams ',vars ',body ',options (w state))))

  (defmacro acl2::defchoose2 (&rest args)
    `(defchoose2 ,@args)))

(defsection show-defchoose2
  :short "Show the event form generated by @(tsee defchoose2),
          without submitting them."
  :long
  "@(def show-defchoose2)
   @(def acl2::show-defchoose2)"

  (defmacro show-defchoose2 (sofun bvars fparams vars body &rest options)
    `(defchoose2-fn
       ',sofun ',bvars ',fparams ',vars ',body ',options (w state)))

  (defmacro acl2::show-defchoose2 (&rest args)
    `(show-defchoose2 ,@args)))

(define defun-sk2-fn (sofun fparams params body options (wrld plist-worldp))
  :returns (event (or (pseudo-event-formp event) (null event)))
  :verify-guards nil
  :short "Validate some of the inputs to @(tsee defun-sk2)
          and generate the event form to submit."
  :long
  "<p>
   We directly check the name, function parameters, individual parameters,
   and top-level structure of the body
   (we check that it has the form @('(forall/exists bound-var(s) ...)')),
   but rely on @(tsee defun-sk) to check the rest of the form.
   After submitting the @(tsee defun-sk) form,
   we check that the function parameters are
   all and only the function variables that
   the function and the rewrite rule depend on.
   </p>"
  (b* (((unless (symbolp sofun))
        (raise "~x0 must be a name." sofun))
       ((unless (funvar-setp fparams wrld))
        (raise "~x0 must be a non-empty list of function variables ~
                without duplicates."
               fparams))
       ((unless (symbol-listp params))
        (raise "~x0 must be a list of symbols." params))
       ((unless (and (consp body)
                     (= (len body) 3)
                     (defun-sk-quantifier-p (first body))
                     (or (symbolp (second body))
                         (symbol-listp (second body)))))
        (raise "~x0 must be a quantified formula." body))
       ((unless (keyword-value-listp options))
        (raise "~x0 must be a list of keyed options." options))
       (info (list 'quant fparams)))
    `(progn
       (defun-sk ,sofun ,params ,body ,@options)
       (table second-order-functions ',sofun ',info)
       (value-triple (check-fparams-dependency ',sofun
                                               'quant
                                               ',fparams
                                               (w state)))
       (value-triple (check-qrewrite-rule-funvars ',sofun
                                                  (w state))))))

(defsection defun-sk2-implementation
  :short "Implementation of @(tsee defun-sk2)."
  :long
  "@(def defun-sk2)
   @(def acl2::defun-sk2)"

  (defmacro defun-sk2 (sofun fparams params body &rest options)
    `(make-event
      (defun-sk2-fn ',sofun ',fparams ',params ',body ',options (w state))))

  (defmacro acl2::defun-sk2 (&rest args)
    `(defun-sk2 ,@args)))

(defsection show-defun-sk2
  :short "Show the event form generated by @(tsee defun-sk2),
          without submitting them."
  :long
  "@(def show-defun-sk2)
   @(def acl2::show-defun-sk2)"

  (defmacro show-defun-sk2 (sofun fparams params body &rest options)
    `(defun-sk2-fn ',sofun ',fparams ',params ',body ',options (w state)))

  (defmacro acl2::show-defun-sk2 (&rest args)
    `(show-defun-sk2 ,@args)))

(define sothmp ((sothm symbolp) (wrld plist-worldp))
  :returns (yes/no "A @(tsee booleanp).")
  :mode :program
  :short "Recognize second-order theorems."
  :long
  "<p>
   A theorem is second-order iff it depends on one or more function variables.
   </p>"
  (not (null (funvars-of-defthm sothm wrld))))

(define no-trivial-pairsp ((alist alistp))
  :returns (yes/no booleanp)
  :short "Check if an alist has no pairs with equal key and value."
  :long
  "<p>
   This is a constraint satisfied by function substitutions;
   see @(tsee fun-substp).
   A pair that substitutes a function with itself would have no effect,
   so such pairs are useless.
   </p>"
  (if (endp alist)
      t
    (let ((pair (car alist)))
      (and (not (equal (car pair) (cdr pair)))
           (no-trivial-pairsp (cdr alist))))))

(define fun-substp (fsbs)
  :returns (yes/no booleanp)
  :short "Recognize function substitutions."
  :long
  "<p>
   A function substitution is an alist from function names to function names,
   with unique keys and with no trivial pairs.
   </p>"
  (and (symbol-symbol-alistp fsbs)
       (no-duplicatesp (alist-keys fsbs))
       (no-trivial-pairsp fsbs))
  :guard-hints (("Goal" :in-theory (enable symbol-symbol-alistp))))

(define funvar-instp (inst (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize instantiations."
  :long
  "<p>
   These are non-empty function substitutions
   whose keys are function variables and whose values are function names.
   </p>"
  (and (fun-substp inst)
       (consp inst)
       (funvar-listp (alist-keys inst) wrld)
       (function-symbol-listp (alist-vals inst) wrld)))

(define funvar-inst-listp (insts (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize @('nil')-terminated lists of instantiations."
  (if (atom insts)
      (null insts)
    (and (funvar-instp (car insts) wrld)
         (funvar-inst-listp (cdr insts) wrld))))

(define sof-instancesp (instmap (wrld plist-worldp))
  :returns (yes/no booleanp)
  :verify-guards nil
  :short "Recognize the information about the instances
          that is associated to second-order function names
          in the @(tsee sof-instances) table."
  :long
  "<p>
   This is an alist from instantiations to function names.
   Each pair in the alist maps an instantiation to the corresponding instance.
   </p>"
  (and (alistp instmap)
       (funvar-inst-listp (alist-keys instmap) wrld)
       (symbol-listp (alist-vals instmap))))

(define get-sof-instance ((inst (funvar-instp inst wrld))
                          (instmap (sof-instancesp instmap wrld))
                          (wrld plist-worldp))
  :returns (instance symbolp
                     :hyp (sof-instancesp instmap wrld)
                     :hints (("Goal" :in-theory (enable sof-instancesp))))
  :verify-guards nil
  :short "Retrieve the instance associated to a given instantiation,
          in the map of known instances of a second-order function."
  :long
  "<p>
   Instantiations are treated as equivalent according to @(tsee alist-equiv).
   If no instance for the instantiation is found, @('nil') is returned.
   </p>"
  (if (endp instmap)
      nil
    (let ((pair (car instmap)))
      (if (alist-equiv (car pair) inst)
          (cdr pair)
        (get-sof-instance inst (cdr instmap) wrld)))))

(define put-sof-instance ((inst (funvar-instp inst wrld))
                          (fun symbolp)
                          (instmap (and (sof-instancesp instmap wrld)
                                        (null
                                         (get-sof-instance inst instmap wrld))))
                          (wrld plist-worldp))
  :returns (new-instmap "A @(tsee sof-instancesp).")
  :verify-guards nil
  :short "Associates an instantiation with an instance
          in an existing map of know instances of a second-order function."
  :long
  "<p>
   The guard requires the absence of an instance for the same instantiation
   (equivalent up to @(tsee alist-equiv)).
   </p>"
  (declare (ignore wrld)) ; only used in guard
  (acons inst fun instmap))

(defsection sof-instances-table
  :short "Table of instances of second-order functions."
  :long
  "<p>
   The known instances of second-order functions are stored in a @(see table).
   The keys are the names of second-order functions that have instances,
   and the values are alists from instantiations to instances.
   </p>"

  (table sof-instances nil nil :guard (and (symbolp acl2::key)
                                           (sof-instancesp acl2::val world))))

(define sof-instances ((sofun (sofunp sofun wrld)) (wrld plist-worldp))
  :returns (instmap "A @(tsee sof-instancesp).")
  :verify-guards nil
  :short "Known instances of a second-order function."
  (let ((table (table-alist 'sof-instances wrld)))
    (cdr (assoc-eq sofun table))))

(define fun-subst-function ((fsbs fun-substp) (fun symbolp) (wrld plist-worldp))
  :returns (new-fun "A @(tsee symbolp).")
  :verify-guards nil
  :short "Apply a function substitution to an individual function."
  :long
  "<p>
   Applying an instantiation to a term involves replacing
   not only the function variables that are keys of the instantiation
   and that occur explicitly in the term,
   but also the ones that occur implicitly in the term
   via occurrences of second-order functions that have
   those function variables as parameters.
   For example, if @('ff') is a second-order function
   with function parameter @('f'),
   and an instantiation @('I') replaces @('f') with @('g'),
   applying @('I') to the term @('(cons (f x) (ff y))')
   should yield the term @('(cons (g x) (gg y))'),
   where @('gg') is the instance that results form applying @('I') to @('ff').
   The @(tsee sof-instances) table is used to find @('gg'):
   @('I') is restricted to the function parameters of @('ff')
   before searching the map of instances of @('ff');
   if the restriction is empty, @('gg') is @('ff'),
   i.e. no replacement takes place.
   If @('gg') does not exist,
   the application of @('I') to @('(cons (f x) (ff y))') fails;
   the user must create @('gg')
   and try applying @('I') to @('(cons (f x) (ff y))') again.
   </p>
   <p>
   When an instantiation is applied
   to the body of a recursive second-order function @('sofun')
   to obtain an instance @('fun'),
   occurrences of @('sofun') in the body must be replaced with @('fun'),
   but at that time @('fun') does not exist yet,
   and thus the table of second-order function instances of @('sofun')
   has no entries for @('fun') yet.
   Thus, it is convenient to use function substitutions (not just instantiation)
   to instantiate terms.
   </p>
   <p>
   The following code applies a function substitution to an individual function,
   in the manner explained above.
   It is used by @(tsee fun-subst-term),
   which applies a function substitution to a term.
   If a needed second-order function instance does not exist, an error occurs.
   </p>"
  (let ((pair (assoc-eq fun fsbs)))
    (if pair
        (cdr pair)
      (if (sofunp fun wrld)
          (let* ((fparams (sofun-fparams fun wrld))
                 (subfsbs (restrict-alist fparams fsbs)))
            (if (null subfsbs)
                fun
              (let* ((instmap (sof-instances fun wrld))
                     (new-fun (get-sof-instance subfsbs instmap wrld)))
                (if new-fun
                    new-fun
                  (raise "~x0 has no instance for ~x1." fun fsbs)))))
        fun))))

(defines fun-subst-term/terms
  :verify-guards nil
  :short "Apply function substitutions to terms."
  :long
  "<p>
   See the discussion in @(tsee fun-subst-function).
   </p>
   @(def fun-subst-term)
   @(def fun-subst-terms)"

  (define fun-subst-term
    ((fsbs fun-substp) (term pseudo-termp) (wrld plist-worldp))
    :returns (new-term "A @(tsee pseudo-termp).")
    (if (or (variablep term)
            (quotep term))
        term
      (let* ((fn (fn-symb term))
             (new-fn (if (symbolp fn)
                         (fun-subst-function fsbs fn wrld)
                       (make-lambda (lambda-formals fn)
                                    (fun-subst-term fsbs
                                                    (lambda-body fn)
                                                    wrld))))
             (new-args (fun-subst-terms fsbs (fargs term) wrld)))
        (cons new-fn new-args))))

  (define fun-subst-terms
    ((fsbs fun-substp) (terms pseudo-term-listp) (wrld plist-worldp))
    :returns (new-terms "A @(tsee pseudo-term-listp).")
    (if (endp terms)
        nil
      (cons (fun-subst-term fsbs (car terms) wrld)
            (fun-subst-terms fsbs (cdr terms) wrld)))))

(defines ext-fun-subst-term/terms/function
  :mode :program
  :short "Extend function substitutions for functional instantiation."
  :long
  "<p>
   An instance @('thm') of a second-order theorem @('sothm') is also a theorem,
   provable using a @(':functional-instance') of @('sothm').
   The pairs of the @(':functional-instance') are
   not only the pairs of the instantiation
   that creates @('thm') from @('sothm'),
   but also all the pairs
   whose first components are second-order functions that @('sothm') depends on
   and whose second components are the corresponding instances.
   </p>
   <p>
   For example,
   if @('sothm') is @('(p (sofun x))'),
   @('sofun') is a second-order function,
   @('p') is a first-order predicate,
   and applying an instantiation @('I') to @('(p (sofun x))')
   yields @('(p (fun x))'),
   then @('thm') is proved using
   @('(:functional-instance sothm (... (sofun fun) ...))'),
   where the first @('...') are the pairs of @('I')
   and the second @('...') are further pairs
   of second-order functions and their instances,
   e.g. if @('sofun') calls a second-order function @('sofun1'),
   the pair @('(sofun1 fun1)') must be in the second @('...'),
   where @('fun1') is the instance of @('sofun1') corresponding to @('I').
   All these pairs are needed to properly instantiate
   the constraints that arise from the @(':functional-instance'),
   which involve the second-order functions that @('sothm') depends on,
   directly or indirectly.
   </p>
   <p>
   The following code extends a function substitution
   (initially an instantiation)
   to contains all those extra pairs.
   The starting point is a term;
   the bodies of second-order functions referenced in the term
   are recursively processed.
   The table of instances of second-order functions is searched,
   similarly to @(tsee fun-subst-function).
   </p>
   @(def ext-fun-subst-term)
   @(def ext-fun-subst-terms)
   @(def ext-fun-subst-function)"

  (define ext-fun-subst-term
    ((term pseudo-termp) (fsbs fun-substp) (wrld plist-worldp))
    :returns (new-term "A @(tsee pseudo-termp).")
    (if (or (variablep term)
            (quotep term))
        fsbs
      (let* ((fn (fn-symb term))
             (fsbs (if (symbolp fn)
                       (ext-fun-subst-function fn fsbs wrld)
                     (ext-fun-subst-term (lambda-body fn) fsbs wrld))))
        (ext-fun-subst-terms (fargs term) fsbs wrld))))

  (define ext-fun-subst-terms
    ((terms pseudo-term-listp) (fsbs fun-substp) (wrld plist-worldp))
    :returns (new-terms "A @(tsee pseudo-term-listp).")
    (if (endp terms)
        fsbs
      (let ((fsbs (ext-fun-subst-term (car terms) fsbs wrld)))
        (ext-fun-subst-terms (cdr terms) fsbs wrld))))

  (define ext-fun-subst-function
    ((fun symbolp) (fsbs fun-substp) (wrld plist-worldp))
    :returns (new-fun "A @(tsee symbolp).")
    (cond
     ((assoc fun fsbs) fsbs)
     ((sofunp fun wrld)
      (b* ((fparams (sofun-fparams fun wrld))
           (subfsbs (restrict-alist fparams fsbs))
           ((if (null subfsbs)) fsbs)
           (instmap (sof-instances fun wrld))
           (funinst (get-sof-instance subfsbs instmap wrld))
           ((unless funinst)
            (raise "~x0 has no instance for ~x1." fun fsbs))
           (fsbs (acons fun funinst fsbs)))
        (case (sofun-kind fun wrld)
          ((plain quant) (ext-fun-subst-term (ubody fun wrld) fsbs wrld))
          (choice (ext-fun-subst-term (defchoose-body fun wrld) fsbs wrld)))))
     (t fsbs))))

(define sothm-inst-pairs ((fsbs fun-substp) (wrld plist-worldp))
  :returns (pairs "A @('doublet-listp').")
  :mode :program
  :short "Create a list of doublets for functional instantiation."
  :long
  "<p>
   From a function substitution obtained by extending an instantiation
   via @(tsee ext-fun-subst-term/terms/function),
   the list of pairs to supply to @(':functional-instance') is obtained.
   Each dotted pair is turned into a doublet
   (a different representation of the pair).
   </p>
   <p>
   In addition, when a dotted pair is encountered
   whose @(tsee car) is the name of a quantifier second-order function,
   an extra pair for instantiating the associated witness is inserted.
   The witnesses of quantifier second-order functions
   must also be part of the @(':functional-instance'),
   because they are referenced by the quantifier second-order functions.
   However, these witnesses are not recorded as second-order functions
   in the table of second-order functions,
   and thus the code of @(tsee ext-fun-subst-term/terms/function)
   does not catch these witnesses.
   </p>"
  (if (endp fsbs)
      nil
    (let* ((pair (car fsbs))
           (1st (car pair))
           (2nd (cdr pair)))
      (if (quant-sofunp 1st wrld)
          (let ((1st-wit (defun-sk-info->witness (defun-sk-check 1st wrld)))
                (2nd-wit (defun-sk-info->witness (defun-sk-check 2nd wrld))))
            (cons (list 1st 2nd)
                  (cons (list 1st-wit 2nd-wit)
                        (sothm-inst-pairs (cdr fsbs) wrld))))
        (cons (list 1st 2nd)
              (sothm-inst-pairs (cdr fsbs) wrld))))))

(define sothm-inst-facts ((fsbs fun-substp) (wrld plist-worldp))
  :returns (fact-names "A @(tsee symbol-listp).")
  :mode :program
  :short "Create list of facts for functional instantiation."
  :long
  "<p>
   When a @(':functional-instance') is used in a proof,
   proof subgoals are created to ensure that the replacing functions
   satisfy all the constraints of the replaced functions.
   In a @(':functional-instance') with a function substitution @('S')
   as calculated by @(tsee ext-fun-subst-term/terms/function),
   each function variable (which comes from the instantiation)
   has no constraints and so no subgoals are generated for them.
   Each second-order function @('sofun') in @('S')
   has the following constraints:
   </p>
   <ul>
     <li>
     If @('sofun') is a plain second-order function,
     the constraint is that
     the application of @('S') to the definition of @('sofun') is a theorem,
     which follows by the construction of the instance @('fun') of @('sofun'),
     i.e. it follows from the definition of @('fun').
     </li>
     <li>
     If @('sofun') is a choice second-order function,
     the constraint is that
     the application of @('S') to the choice axiom of @('sofun') is a theorem,
     which follows by the construction of the instance @('fun') of @('sofun'),
     i.e. it follows from the choice axiom of @('fun').
     </li>
     <li>
     If @('sofun') is a quantifier second-order function,
     the constraints are that
     (1) the application of @('S')
     to the rewrite rule generated by the @(tsee defun-sk) of @('sofun'),
     and (2) the application of @('S') to the definition of @('sofun'),
     are both theorems,
     which both follow by the construction
     of the instance @('fun') of @('sofun'),
     i.e. they follow from
     (1) the rewrite rule generated by the @(tsee defun-sk) of @('fun')
     and (2) the definition of @('fun').
     </li>
   </ul>
   <p>
   The list of facts needed to prove these constraints is determined
   by the function substitution @('S').
   For each pair @('(fun1 . fun2)') of the function substitution:
   </p>
   <ul>
     <li>
     If @('fun1') is a plain second-order function,
     the fact used in the the proof is the definition of @('fun2')
     (by construction, since @('fun2') is an instance of @('fun1'),
     @('fun2') is introduced by a @(tsee defun)),
     whose name is the name of @('fun2').
     </li>
     <li>
     If @('fun1') is a choice second-order function,
     the fact used in the proof is the @(tsee defchoose) axiom of @('fun2')
     (by construction, since @('fun2') is an instance of @('fun1'),
     @('fun2') is introduced by a @(tsee defchoose)),
     whose name is the name of @('fun2').
     </li>
     <li>
     If @('fun1') is a quantifier second-order function,
     the fact used in the proof is
     the @(tsee defun-sk) rewrite rule of @('fun2')
     (by construction, since @('fun2') is an instance of @('fun1'),
     @('fun2') is introduced by a @(tsee defun-sk)).
     </li>
     <li>
     Otherwise, @('fun1') is a function variable, which has no constraints,
     so no fact is used in the proof.
     </li>
   </ul>"
  (if (endp fsbs)
      nil
    (let* ((pair (car fsbs))
           (1st (car pair))
           (2nd (cdr pair)))
      (cond ((or (plain-sofunp 1st wrld)
                 (choice-sofunp 1st wrld))
             (cons 2nd (sothm-inst-facts (cdr fsbs) wrld)))
            ((quant-sofunp 1st wrld)
             (cons (defun-sk-info->rewrite-name (defun-sk-check 2nd wrld))
                   (sothm-inst-facts (cdr fsbs) wrld)))
            (t (sothm-inst-facts (cdr fsbs) wrld))))))

(define sothm-inst-proof
  ((sothm symbolp) (fsbs fun-substp) (wrld plist-worldp))
  :returns (instructions "A @(tsee true-listp).")
  :mode :program
  :short "Proof builder instructions to prove
          instances of second-order theorems."
  :long
  "<p>
   Instances of second-order theorems are proved using the ACL2 proof builder.
   Each such instance is proved by
   first using the @(':functional-instance')
   determined by @(tsee sothm-inst-pairs),
   then using the facts computed by @(tsee sothm-inst-facts) on the subgoals.
   Each sugoal only needs a subset of those facts,
   but for simplicity all the facts are used for each subgoal,
   using the proof builder
   <see topic='@(url acl2-pc::repeat)'>@(':repeat')</see> command.
   Since sometimes the facts are not quite identical to the subgoals,
   the proof builder
   <see topic='@(url acl2-pc::prove)'>@(':prove')</see> command
   is used to iron out any such differences.
   </p>"
  `(:instructions
    ((:use (:functional-instance ,sothm ,@(sothm-inst-pairs fsbs wrld)))
     (:repeat (:then (:use ,@(sothm-inst-facts fsbs wrld)) :prove)))))

(define check-sothm-inst (sothm-inst (wrld plist-worldp))
  :returns (yes/no "A @(tsee booleanp).")
  :mode :program
  :short "Recognize designations of instances of second-order theorems."
  :long
  "<p>
   A designation of an instance of a second-order theorem has the form
   @('(sothm (f1 . g1) ... (fM . gM))'),
   where @('sothm') is a second-order theorem
   and @('((f1 . g1) ... (fM . gM))') is an instantiation.
   These designations are used in @(tsee defthm-inst).
   </p>"
  (and (true-listp sothm-inst)
       (>= (len sothm-inst) 2)
       (sothmp (car sothm-inst) wrld)
       (funvar-instp (cdr sothm-inst) wrld)))

(define defthm-inst-fn (thm sothm-inst rest (wrld plist-worldp))
  :returns (event "A @(tsee pseudo-event-formp) or @('nil').")
  :mode :program
  :short "Validate the inputs to @(tsee defthm-inst)
          and generate the event form to submit."
  :long
  "<p>
   We directly check the form except for the @(':rule-classes') option,
   relying on @(tsee defthm) to check it.
   </p>
   <p>
   Supplying @(':hints') causes an error
   because @(tsee defthm) disallows both @(':hints') and @(':instructions').
   </p>
   <p>
   Supplying @('otf-flg') has no effect
   because the proof is via the proof builder.
   </p>"
  (b* (((unless (symbolp thm)) (raise "~x0 must be a name." thm))
       ((unless (check-sothm-inst sothm-inst wrld))
        (raise "~x0 must be the name of a second-order theorem ~
                followed by the pairs of an instantiation."
               sothm-inst))
       (sothm (car sothm-inst))
       (inst (cdr sothm-inst))
       ((unless (subsetp (alist-keys inst) (funvars-of-defthm sothm wrld)))
        (raise "Each function variable key of ~x0 must be ~
                among function variable that ~x1 depends on."
               inst sothm))
       (sothm-formula (formula sothm nil wrld))
       (thm-formula (fun-subst-term inst sothm-formula wrld))
       (thm-formula (untranslate thm-formula t wrld))
       (fsbs (ext-fun-subst-term sothm-formula inst wrld))
       (thm-proof (sothm-inst-proof sothm fsbs wrld)))
    `(defthm ,thm ,thm-formula ,@thm-proof ,@rest)))

(defsection defthm-inst-implementation
  :short "Implementation of @(tsee defthm-inst)."
  :long
  "@(def defthm-inst)
   @(def acl2::defthm-inst)"

  (defmacro defthm-inst (thm sothminst &rest rest)
    `(make-event
      (defthm-inst-fn ',thm ',sothminst ',rest (w state))))

  (defmacro acl2::defthm-inst (&rest args)
    `(defthm-inst ,@args)))

(defsection show-defthm-inst
  :short "Show the event form generated by @(tsee defthm-inst),
          without submitting them."
  :long
  "@(def show-defthm-inst)
   @(def acl2::show-defthm-inst)"

  (defmacro show-defthm-inst (thm sothminst &rest rest)
    `(defthm-inst-fn ',thm ',sothminst ',rest (w state)))

  (defmacro acl2::show-defthm-inst (&rest args)
    `(show-defthm-inst ,@args)))

(define check-sofun-inst (sofun-inst (wrld plist-worldp))
  :returns (yes/no "A @(tsee booleanp).")
  :verify-guards nil
  :short "Recognize designations of instances of second-order functions."
  :long
  "<p>
   A designation of an instance of a second-order function has the form
   @('(sofun (f1 . g1) ... (fM . gM))'),
   where @('sofun') is a second-order function
   and @('((f1 . g1) ... (fM . gM))') is an instantiation.
   These designations are used in @(tsee defun-inst).
   </p>"
  (and (true-listp sofun-inst)
       (>= (len sofun-inst) 2)
       (sofunp (car sofun-inst) wrld)
       (funvar-instp (cdr sofun-inst) wrld)))

(define defun-inst-plain-events ((fun symbolp)
                                 (fparams (or (funvar-setp fparams wrld)
                                              (null fparams)))
                                 (sofun (plain-sofunp sofun wrld))
                                 inst
                                 (options keyword-value-listp)
                                 (wrld plist-worldp))
  :returns (events "A @(tsee pseudo-event-form-listp).")
  :mode :program
  :short "Generate a list of events to submit,
          when instantiating a plain second-order function."
  :long
  "<p>
   Only the @(':verify-guards') option may be present.
   </p>
   <p>
   We add @('fun') to the table of second-order functions
   iff it is second-order.
   </p>
   <p>
   If @('sofun') (and consequently @('fun')) is recursive,
   we extend the instantiation with @('(sofun . fun)'),
   to ensure that the recursive calls are properly transformed.
   </p>"
  (b* (((unless (subsetp (keywords-of-keyword-value-list options)
                         '(:verify-guards)))
        (raise "~x0 must include only :VERIFY-GUARDS, ~
                because ~x1 is a plain second-order function."
               options sofun))
       (verify-guards (let ((verify-guards-option
                             (assoc-keyword :verify-guards options)))
                        (if verify-guards-option
                            (cadr verify-guards-option)
                          (guard-verified-p sofun wrld))))
       (sofun-body (ubody sofun wrld))
       (sofun-measure (if (recursivep sofun nil wrld)
                          (measure sofun wrld)
                        nil))
       (sofun-guard (guard sofun nil wrld))
       (fsbs (if sofun-measure (acons sofun fun inst) inst))
       (fun-body (fun-subst-term fsbs sofun-body wrld))
       (fun-body (untranslate fun-body nil wrld))
       (fun-measure (fun-subst-term inst sofun-measure wrld))
       (fun-measure (untranslate fun-measure nil wrld))
       (fun-guard (fun-subst-term inst sofun-guard wrld))
       (fun-guard (untranslate fun-guard t wrld))
       (sofun-tt-name `(:termination-theorem ,sofun))
       (sofun-tt-formula (and (recursivep sofun nil wrld)
                              (termination-theorem sofun wrld)))
       (fsbs (ext-fun-subst-term sofun-tt-formula inst wrld))
       (fun-tt-proof (sothm-inst-proof sofun-tt-name fsbs wrld))
       (hints (if fun-measure `(:hints (("Goal" ,@fun-tt-proof))) nil))
       (measure (if fun-measure `(:measure ,fun-measure) nil))
       (info (list 'plain fparams))
       (table-event (if fparams
                        (list `(table second-order-functions ',fun ',info))
                      nil)))
    `((defun ,fun ,(formals sofun wrld)
        (declare (xargs :guard ,fun-guard
                        :verify-guards ,verify-guards
                        ,@measure
                        ,@hints))
        ,fun-body)
      ,@table-event)))

(define defun-inst-choice-events ((fun symbolp)
                                  (fparams (or (funvar-setp fparams wrld)
                                               (null fparams)))
                                  (sofun (choice-sofunp sofun wrld))
                                  inst
                                  (options keyword-value-listp)
                                  (wrld plist-worldp))
  :returns (events "A @(tsee pseudo-event-form-listp).")
  :mode :program
  :short "Generate a list of events to submit,
          when instantiating a choice second-order function."
  :long
  "<p>
   No option may be present.
   </p>
   <p>
   We add @('fun') to the table of second-order functions
   iff it is second-order.
   </p>"
  (b* (((unless (null options))
        (raise "~x0 must include no options, ~
                because ~x1 is a choice second-order function."
               options sofun))
       (bound-vars (defchoose-bound-vars sofun wrld))
       (sofun-body (defchoose-body sofun wrld))
       (fun-body (fun-subst-term inst sofun-body wrld))
       (fun-body (untranslate fun-body nil wrld))
       (info (list 'choice fparams))
       (table-event (if fparams
                        (list `(table second-order-functions ',fun ',info))
                      nil)))
    `((defchoose ,fun ,bound-vars ,(formals sofun wrld)
        ,fun-body
        :strengthen ,(defchoose-strengthen sofun wrld))
      ,@table-event)))

(define defun-inst-quant-events ((fun symbolp)
                                 (fparams (or (funvar-setp fparams wrld)
                                              (null fparams)))
                                 (sofun (quant-sofunp sofun wrld))
                                 inst
                                 (options keyword-value-listp)
                                 (wrld plist-worldp))
  :returns (events "A @(tsee pseudo-event-form-listp).")
  :mode :program
  :short "Generate a list of events to submit,
          when instantiating a quantifier second-order function."
  :long
  "<p>
   Only the @(':skolem-name'), @(':thm-name'), and @(':rewrite') options
   may be present.
   </p>
   <p>
   We add @('fun') to the table of second-order functions
   iff it is second-order.
   </p>"
  (b* (((unless (subsetp (keywords-of-keyword-value-list options)
                         '(:skolem-name :thm-name :rewrite)))
        (raise "~x0 must include only :SKOLEM-NAME, :THM-NAME, and :REWRITE, ~
                because ~x1 is a quantifier second-order function."
               options sofun))
       (sofun-info (defun-sk-check sofun wrld))
       (bound-vars (defun-sk-info->bound-vars sofun-info))
       (quant (defun-sk-info->quantifier sofun-info))
       (sofun-matrix (defun-sk-info->matrix sofun-info))
       (fun-matrix (fun-subst-term inst sofun-matrix wrld))
       (fun-matrix (untranslate fun-matrix nil wrld))
       (rewrite-option (assoc-keyword :rewrite options))
       (rewrite
        (if rewrite-option
            (cadr rewrite-option)
          (let ((qrkind (defun-sk-info->rewrite-kind sofun-info)))
            (case qrkind
              (:default :default)
              (:direct :direct)
              (:custom
               (let* ((fsbs (acons sofun fun inst))
                      (rule-name (defun-sk-info->rewrite-name sofun-info))
                      (term (formula rule-name nil wrld)))
                 (fun-subst-term fsbs term wrld)))))))
       (skolem-name (let ((skolem-name-option
                           (assoc-keyword :skolem-name options)))
                      (if skolem-name-option
                          `(:skolem-name ,(cadr skolem-name-option))
                        nil)))
       (thm-name (let ((thm-name-option
                        (assoc-keyword :thm-name options)))
                   (if thm-name-option
                       `(:thm-name ,(cadr thm-name-option))
                     nil)))
       (sofun-guard (guard sofun nil wrld))
       (fun-guard (fun-subst-term inst sofun-guard wrld))
       (fun-guard (untranslate fun-guard t wrld))
       (wit-dcl `(declare (xargs :guard ,fun-guard :verify-guards nil)))
       (info (list 'quant fparams))
       (table-event (if fparams
                        (list `(table second-order-functions ',fun ',info))
                      nil)))
    `((defun-sk ,fun ,(formals sofun wrld)
        (,quant ,bound-vars ,fun-matrix)
        :strengthen ,(defun-sk-info->strengthen sofun-info)
        :quant-ok t
        ,@(and (eq quant 'forall)
               (list :rewrite rewrite))
        ,@skolem-name
        ,@thm-name
        :witness-dcls (,wit-dcl))
      ,@table-event
      (value-triple (check-qrewrite-rule-funvars ',fun (w state))))))

(define defun-inst-fn (fun fparams-or-sofuninst rest (wrld plist-worldp))
  :returns (event "A @(tsee pseudo-event-formp) or @('nil').")
  :mode :program
  :short "Validate some of the inputs to @(tsee defun-inst)
          and generate the event form to submit."
  :long
  "<p>
   We directly check the name, function parameters, and instance designation,
   we directly check the correct presence of keyed options
   (in @(tsee defun-inst-plain-events),
   @(tsee defun-inst-choice-events),
   and @(tsee defun-inst-quant-events)),
   but rely on @(tsee defun), @(tsee defchoose), and @(tsee defun-sk)
   to check the values of the keyed options.
   </p>
   <p>
   Prior to introducing @('fun'),
   we generate local events
   to avoid errors due to ignored or irrelevant formals in @('fun')
   (which may happen if @('sofun') has ignored or irrelevant formals).
   We add @('fun') to the table of instances of second-order functions.
   After introducing @('fun'),
   we check that the function parameters are
   all and only the function variables that the function depends on.
   </p>"
  (b* (((unless (symbolp fun)) (raise "~x0 must be a name." fun))
       (2nd-order (funvar-setp fparams-or-sofuninst wrld))
       ((unless (or 2nd-order
                    (check-sofun-inst fparams-or-sofuninst wrld)))
        (raise "~x0 must be either a non-empty list of ~
                function variables without duplicates ~
                or the name of a second-order function ~
                followed by the pairs of an instantiation."
               fparams-or-sofuninst))
       (fparams (if 2nd-order fparams-or-sofuninst nil))
       ((unless (or (not 2nd-order)
                    (and (consp rest)
                         (check-sofun-inst (car rest) wrld))))
        (raise "~x0 must start with the name of a second-order function ~
                followed by an instantiation."
               rest))
       (sofun-inst (if 2nd-order (car rest) fparams-or-sofuninst))
       (sofun (car sofun-inst))
       (inst (cdr sofun-inst))
       ((unless (subsetp (alist-keys inst) (sofun-fparams sofun wrld)))
        (raise "Each function variable key of ~x0 must be ~
                among the function parameters ~x1 of ~x2."
               inst (sofun-fparams sofun wrld) sofun))
       (options (if 2nd-order (cdr rest) rest))
       ((unless (keyword-value-listp options))
        (raise "~x0 must be a list of keyed options." options))
       ((unless (no-duplicatesp (keywords-of-keyword-value-list options)))
        (raise "~x0 must have unique keywords." options))
       (fun-intro-events
        (case (sofun-kind sofun wrld)
          (plain
           (defun-inst-plain-events fun fparams sofun inst options wrld))
          (choice
           (defun-inst-choice-events fun fparams sofun inst options wrld))
          (quant
           (defun-inst-quant-events fun fparams sofun inst options wrld))))
       (instmap (sof-instances sofun wrld))
       (new-instmap (put-sof-instance inst fun instmap wrld)))
    `(encapsulate
       ()
       (set-ignore-ok t)
       (set-irrelevant-formals-ok t)
       ,@fun-intro-events
       (table sof-instances ',sofun ',new-instmap)
       (value-triple (check-fparams-dependency ',fun
                                               ',(sofun-kind sofun wrld)
                                               ',fparams
                                               (w state))))))

(defsection defun-inst-implementation
  :short "Implementation of @(tsee defun-inst)."
  :long
  "@(def defun-inst)
   @(def acl2::defun-inst)"

  (defmacro defun-inst (fun fparams-or-sofuninst &rest rest)
    `(make-event
      (defun-inst-fn ',fun ',fparams-or-sofuninst ',rest (w state))))

  (defmacro acl2::defun-inst (&rest args)
    `(defun-inst ,@args)))

(defsection show-defun-inst
  :short "Show the event form generated by @(tsee defun-inst),
          without submitting them."
  :long
  "@(def show-defun-inst)
   @(def acl2::show-defun-inst)"

  (defmacro show-defun-inst (fun fparams-or-sofuninst &rest rest)
    `(defun-inst-fn ',fun ',fparams-or-sofuninst ',rest (w state)))

  (defmacro acl2::show-defun-inst (&rest args)
    `(show-defun-inst ,@args)))
