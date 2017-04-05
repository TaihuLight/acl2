; Copyright (C) 2016, Regents of the University of Texas
; Marijn Heule, Warren A. Hunt, Jr., and Matt Kaufmann
; License: A 3-clause BSD license.  See the LICENSE file distributed with ACL2.

(in-package "LRAT")

;! Limits and Recognizers

; Constants

(defconst  *2^0* (expt 2  0))
(defconst  *2^1* (expt 2  1))
(defconst  *2^2* (expt 2  2))
(defconst  *2^3* (expt 2  3))
(defconst  *2^4* (expt 2  4))
(defconst  *2^5* (expt 2  5))
(defconst  *2^6* (expt 2  6))
(defconst  *2^8* (expt 2  8))
(defconst *2^10* (expt 2 10))
(defconst *2^16* (expt 2 16))
(defconst *2^24* (expt 2 24))
(defconst *2^28* (expt 2 28))
(defconst *2^32* (expt 2 32))
(defconst *2^40* (expt 2 40))
(defconst *2^48* (expt 2 48))
(defconst *2^56* (expt 2 56))
(defconst *2^57* (expt 2 57))
(defconst *2^58* (expt 2 58))
(defconst *2^59* (expt 2 59))
(defconst *2^60* (expt 2 60))
(defconst *2^64* (expt 2 64))

(defconst *nmax* *2^59*)
(defconst *-nmax* (- *nmax*))

; Declarations

(defmacro u01 (x)   `(the (unsigned-byte  1) ,x))
(defmacro u02 (x)   `(the (unsigned-byte  2) ,x))
(defmacro u03 (x)   `(the (unsigned-byte  3) ,x))
(defmacro u04 (x)   `(the (unsigned-byte  4) ,x))
(defmacro u05 (x)   `(the (unsigned-byte  5) ,x))
(defmacro u06 (x)   `(the (unsigned-byte  6) ,x))
(defmacro u08 (x)   `(the (unsigned-byte  8) ,x))
(defmacro u10 (x)   `(the (unsigned-byte 10) ,x))
(defmacro u16 (x)   `(the (unsigned-byte 16) ,x))
(defmacro u24 (x)   `(the (unsigned-byte 24) ,x))
(defmacro u28 (x)   `(the (unsigned-byte 28) ,x))
(defmacro u32 (x)   `(the (unsigned-byte 32) ,x))
(defmacro u40 (x)   `(the (unsigned-byte 40) ,x))
(defmacro u48 (x)   `(the (unsigned-byte 48) ,x))
(defmacro u56 (x)   `(the (unsigned-byte 56) ,x))
(defmacro u59 (x)   `(the (unsigned-byte 59) ,x))
(defmacro u60 (x)   `(the (unsigned-byte 60) ,x))
(defmacro u64 (x)   `(the (unsigned-byte 64) ,x))

(defmacro s01 (x)   `(the (signed-byte  1) ,x))
(defmacro s02 (x)   `(the (signed-byte  2) ,x))
(defmacro s03 (x)   `(the (signed-byte  3) ,x))
(defmacro s04 (x)   `(the (signed-byte  4) ,x))
(defmacro s05 (x)   `(the (signed-byte  5) ,x))
(defmacro s06 (x)   `(the (signed-byte  6) ,x))
(defmacro s08 (x)   `(the (signed-byte  8) ,x))
(defmacro s10 (x)   `(the (signed-byte 10) ,x))
(defmacro s16 (x)   `(the (signed-byte 16) ,x))
(defmacro s24 (x)   `(the (signed-byte 24) ,x))
(defmacro s28 (x)   `(the (signed-byte 28) ,x))
(defmacro s32 (x)   `(the (signed-byte 32) ,x))
(defmacro s40 (x)   `(the (signed-byte 40) ,x))
(defmacro s48 (x)   `(the (signed-byte 48) ,x))
(defmacro s56 (x)   `(the (signed-byte 56) ,x))
(defmacro s57 (x)   `(the (signed-byte 57) ,x))
(defmacro s58 (x)   `(the (signed-byte 58) ,x))
(defmacro s59 (x)   `(the (signed-byte 59) ,x))
(defmacro s60 (x)   `(the (signed-byte 60) ,x))
(defmacro s64 (x)   `(the (signed-byte 64) ,x))

; Fixers

(defmacro n01 (x)   `(logand ,x ,(1- *2^1*)))
(defmacro n02 (x)   `(logand ,x ,(1- *2^2*)))
(defmacro n03 (x)   `(logand ,x ,(1- *2^3*)))
(defmacro n04 (x)   `(logand ,x ,(1- *2^4*)))
(defmacro n05 (x)   `(logand ,x ,(1- *2^5*)))
(defmacro n06 (x)   `(logand ,x ,(1- *2^6*)))
(defmacro n08 (x)   `(logand ,x ,(1- *2^8*)))
(defmacro n10 (x)   `(logand ,x ,(1- *2^10*)))
(defmacro n16 (x)   `(logand ,x ,(1- *2^16*)))
(defmacro n24 (x)   `(logand ,x ,(1- *2^24*)))
(defmacro n28 (x)   `(logand ,x ,(1- *2^28*)))
(defmacro n32 (x)   `(logand ,x ,(1- *2^32*)))
(defmacro n40 (x)   `(logand ,x ,(1- *2^40*)))
(defmacro n48 (x)   `(logand ,x ,(1- *2^48*)))
(defmacro n56 (x)   `(logand ,x ,(1- *2^56*)))
(defmacro n57 (x)   `(logand ,x ,(1- *2^57*)))
(defmacro n58 (x)   `(logand ,x ,(1- *2^58*)))
(defmacro n59 (x)   `(logand ,x ,(1- *2^59*)))
(defmacro n60 (x)   `(logand ,x ,(1- *2^60*)))
(defmacro n64 (x)   `(logand ,x ,(1- *2^64*)))

(defmacro i01 (x)   `(let ((sx (logand ,x ,(1- *2^1*))))  (if (>= sx *2^0*)  (+ sx (- *2^1*))  sx)))
(defmacro i02 (x)   `(let ((sx (logand ,x ,(1- *2^2*))))  (if (>= sx *2^1*)  (+ sx (- *2^2*))  sx)))
(defmacro i03 (x)   `(let ((sx (logand ,x ,(1- *2^3*))))  (if (>= sx *2^2*)  (+ sx (- *2^3*))  sx)))
(defmacro i04 (x)   `(let ((sx (logand ,x ,(1- *2^4*))))  (if (>= sx *2^3*)  (+ sx (- *2^4*))  sx)))
(defmacro i05 (x)   `(let ((sx (logand ,x ,(1- *2^5*))))  (if (>= sx *2^4*)  (+ sx (- *2^5*))  sx)))
(defmacro i06 (x)   `(let ((sx (logand ,x ,(1- *2^6*))))  (if (>= sx *2^5*)  (+ sx (- *2^6*))  sx)))
(defmacro i08 (x)   `(let ((sx (logand ,x ,(1- *2^8*))))  (if (>= sx *2^7*)  (+ sx (- *2^8*))  sx)))
(defmacro i10 (x)   `(let ((sx (logand ,x ,(1- *2^10*)))) (if (>= sx *2^9*)  (+ sx (- *2^10*)) sx)))
(defmacro i16 (x)   `(let ((sx (logand ,x ,(1- *2^16*)))) (if (>= sx *2^15*) (+ sx (- *2^16*)) sx)))
(defmacro i24 (x)   `(let ((sx (logand ,x ,(1- *2^24*)))) (if (>= sx *2^23*) (+ sx (- *2^24*)) sx)))
(defmacro i32 (x)   `(let ((sx (logand ,x ,(1- *2^32*)))) (if (>= sx *2^31*) (+ sx (- *2^32*)) sx)))
(defmacro i40 (x)   `(let ((sx (logand ,x ,(1- *2^40*)))) (if (>= sx *2^39*) (+ sx (- *2^40*)) sx)))
(defmacro i48 (x)   `(let ((sx (logand ,x ,(1- *2^48*)))) (if (>= sx *2^47*) (+ sx (- *2^48*)) sx)))
(defmacro i56 (x)   `(let ((sx (logand ,x ,(1- *2^56*)))) (if (>= sx *2^55*) (+ sx (- *2^56*)) sx)))
(defmacro i57 (x)   `(let ((sx (logand ,x ,(1- *2^57*)))) (if (>= sx *2^56*) (+ sx (- *2^57*)) sx)))
(defmacro i58 (x)   `(let ((sx (logand ,x ,(1- *2^58*)))) (if (>= sx *2^57*) (+ sx (- *2^58*)) sx)))
(defmacro i60 (x)   `(let ((sx (logand ,x ,(1- *2^60*)))) (if (>= sx *2^59*) (+ sx (- *2^60*)) sx)))
(defmacro i64 (x)   `(let ((sx (logand ,x ,(1- *2^64*)))) (if (>= sx *2^63*) (+ sx (- *2^64*)) sx)))

; Recognizers

(defmacro n01p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^1*))))
(defmacro n02p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^2*))))
(defmacro n03p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^3*))))
(defmacro n04p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^4*))))
(defmacro n05p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^5*))))
(defmacro n06p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^6*))))
(defmacro n08p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^8*))))
(defmacro n10p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^10*))))
(defmacro n16p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^16*))))
(defmacro n24p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^24*))))
(defmacro n28p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^28*))))
(defmacro n32p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^32*))))
(defmacro n40p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^40*))))
(defmacro n48p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^48*))))
(defmacro n56p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^56*))))
(defmacro n57p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^57*))))
(defmacro n58p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^58*))))
(defmacro n59p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^59*))))
(defmacro n60p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^60*))))
(defmacro n64p (x) `(let ((x ,x)) (and (integerp x) (<= 0 x) (< x *2^64*))))

(defmacro i01p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^0*)  x) (< x *2^0*))))
(defmacro i02p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^1*)  x) (< x *2^1*))))
(defmacro i03p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^2*)  x) (< x *2^2*))))
(defmacro i04p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^3*)  x) (< x *2^3*))))
(defmacro i05p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^4*)  x) (< x *2^4*))))
(defmacro i06p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^5*)  x) (< x *2^5*))))
(defmacro i08p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^7*)  x) (< x *2^7*))))
(defmacro i10p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^9*)  x) (< x *2^9*))))
(defmacro i16p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^15*) x) (< x *2^15*))))
(defmacro i24p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^23*) x) (< x *2^23*))))
(defmacro i28p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^27*) x) (< x *2^27*))))
(defmacro i32p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^31*) x) (< x *2^31*))))
(defmacro i40p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^39*) x) (< x *2^39*))))
(defmacro i48p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^47*) x) (< x *2^47*))))
(defmacro i56p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^55*) x) (< x *2^55*))))
(defmacro i57p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^56*) x) (< x *2^56*))))
(defmacro i58p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^57*) x) (< x *2^57*))))
(defmacro i60p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^59*) x) (< x *2^59*))))
(defmacro i64p (x) `(let ((x ,x)) (and (integerp x) (<= (- *2^63*) x) (< x *2^63*))))


; List Recognizers

(defun n59-listp (xs)
  (declare (xargs :guard t))
  (if (atom xs)
      (null xs)
    (and (n59p (car xs))
         (n59-listp (cdr xs)))))

(defthm n59-listp-forward
  (implies (n59-listp x)
           (true-listp x))
  :rule-classes (:forward-chaining :rewrite))

(defthm nth-n59-listp
  (implies (and (n59-listp xs)
                (natp i)
                (< i (len xs)))
           (n59p (nth i xs)))
  :rule-classes
  ((:type-prescription
    :corollary
    (implies (and (n59-listp xs)
                  (natp i)
                  (< i (len xs)))
             (natp (nth i xs))))
   (:linear
    :corollary
    (implies (and (n59-listp xs)
                  (natp i)
                  (< i (len xs)))
             (and (<= 0 (nth i xs))
                  (<    (nth i xs) *2^59*))))))


(defun i60-listp (xs)
  (declare (xargs :guard t))
  (if (atom xs)
      (null xs)
    (and (i60p (car xs))
         (i60-listp (cdr xs)))))

(defthm i60-listp-forward
  (implies (i60-listp x)
           (true-listp x))
  :rule-classes (:forward-chaining :rewrite))

(defthm nth-i60-listp
  (implies (and (i60-listp xs)
                (natp i)
                (< i (len xs)))
           (i60p (nth i xs)))
  :rule-classes
  ((:type-prescription
    :corollary
    (implies (and (i60-listp xs)
                  (natp i)
                  (< i (len xs)))
             (integerp (nth i xs))))
   (:linear
    :corollary
    (implies (and (i60-listp xs)
                  (natp i)
                  (< i (len xs)))
             (and (<= (- *2^59*) (nth i xs))
                  (<  (nth i xs) *2^59*))))))
