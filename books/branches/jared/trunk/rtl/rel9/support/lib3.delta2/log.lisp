; RTL - A Formal Theory of Register-Transfer Logic and Computer Arithmetic 
; Copyright (C) 1995-2013 Advanced Mirco Devices, Inc. 
;
; Contact:
;   David Russinoff
;   1106 W 9th St., Austin, TX 78703
;   http://www.russsinoff.com/
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.
;
; This program is distributed in the hope that it will be useful but WITHOUT ANY
; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
; PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along with
; this program; see the file "gpl.txt" in this directory.  If not, write to the
; Free Software Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA
; 02110-1335, USA.
;
; Author: David M. Russinoff (david@russinoff.com)

(in-package "ACL2")

(include-book "arithmetic-5/top" :dir :system)

(local (include-book "../lib3/top"))

(defund fl (x)
  (declare (xargs :guard (real/rationalp x)))
  (floor x 1))

(defund cg (x)
  (declare (xargs :guard (real/rationalp x)))
  (- (fl (- x))))

(defund bvecp (x k)
  (declare (xargs :guard (integerp k)))
  (and (integerp x)
       (<= 0 x)
       (< x (expt 2 k))))

(defund bits (x i j)
  (declare (xargs :guard (and (integerp x)
                              (integerp i)
                              (integerp j))))
  (mbe :logic (if (or (not (integerp i))
                      (not (integerp j)))
                  0
                (fl (/ (mod x (expt 2 (1+ i))) (expt 2 j))))
       :exec  (if (< i j)
                  0
                (logand (ash x (- j)) (1- (ash 1 (1+ (- i j))))))))
(defund bitn (x n)
  (declare (xargs :guard (and (integerp x)
                              (integerp n))))
  (mbe :logic (bits x n n)
       :exec  (if (evenp (ash x (- n))) 0 1)))

(defund binary-cat (x m y n)
  (declare (xargs :guard (and (integerp x)
                              (integerp y)
                              (natp m)
                              (natp n))))
  (if (and (natp m) (natp n))
      (+ (* (expt 2 n) (bits x (1- m) 0))
         (bits y (1- n) 0))
    0))

(defun formal-+ (x y)
  (declare (xargs :guard t))
  (if (and (acl2-numberp x) (acl2-numberp y))
      (+ x y)
    (list '+ x y)))

(defun cat-size (x)
  (declare (xargs :guard (and (true-listp x) (evenp (length x)))))
  (if (endp (cddr x))
      (cadr x)
    (formal-+ (cadr x)
	      (cat-size (cddr x)))))

(defmacro cat (&rest x)
  (declare (xargs :guard (and x (true-listp x) (evenp (length x)))))
  (cond ((endp (cddr x))
         `(bits ,(car x) ,(formal-+ -1 (cadr x)) 0))
        ((endp (cddddr x))
         `(binary-cat ,@x))
        (t
         `(binary-cat ,(car x) 
                      ,(cadr x) 
                      (cat ,@(cddr x)) 
                      ,(cat-size (cddr x))))))

(defund mulcat (l n x)
  (declare (xargs :guard (and (integerp l) (< 0 l) (acl2-numberp n) (natp x))))
  (mbe :logic (if (and (integerp n) (> n 0))
                  (cat (mulcat l (1- n) x)
                       (* l (1- n))
                       x
                       l)
                0)
       :exec  (cond ((eql n 1)
                     (bits x (1- l) 0))
                    ((and (integerp n) (> n 0))
                     (cat (mulcat l (1- n) x)
                          (* l (1- n))
                          x
                          l))
                    (t 0))))


;;;**********************************************************************
;;;                       LOGAND, LOGIOR, and LOGXOR
;;;**********************************************************************

(in-theory (disable logand logior logxor))

(defthmd logand-def
    (implies (and (case-split (integerp i))
		  (case-split (integerp j)))
	     (equal (logand i j)
		    (+ (* 2 (logand (fl (* 1/2 i)) (fl (* 1/2 j))))
		       (logand (mod i 2) (mod j 2)))))
  :rule-classes ((:definition :controller-alist ((binary-logand t t)))))


(defthmd logior-def
    (implies (and (case-split (integerp i))
		  (case-split (integerp j)))
	     (equal (logior i j)
		    (+ (* 2 (logior (fl (* 1/2 i)) (fl (* 1/2 j))))
		       (logior (mod i 2) (mod j 2)))))
  :rule-classes ((:definition :controller-alist ((binary-logior t t)))))



(defthmd logxor-def
    (implies (and (case-split (integerp i))
		  (case-split (integerp j)))
	     (equal (logxor i j)
		    (+ (* 2 (logxor (fl (* 1/2 i)) (fl (* 1/2 j))))
		       (logxor (mod i 2) (mod j 2)))))
  :rule-classes ((:definition :controller-alist ((binary-logxor t t)))))


(defthm logand-natp
    (implies (and (natp i)
		  (integerp j))
	     (natp (logand i j)))
  :rule-classes (:type-prescription :rewrite))

(defthm logand-natp-2
    (implies (and (integerp i)
		  (natp j))
	     (natp (logand i j)))
  :rule-classes (:type-prescription :rewrite))


(defthm logand-bvecp
    (implies (and (natp n)
		  (bvecp x n)
		  (integerp y))
	     (bvecp (logand x y) n))
    :hints (("Goal" :by logand-bvecp-g)))

(defthm logior-natp
    (implies (and (natp i)
		  (natp j))
	     (natp (logior i j)))
  :rule-classes (:type-prescription :rewrite))

(defthm logior-bvecp
    (implies (and (bvecp x n)
		  (bvecp y n))
	     (bvecp (logior x y) n)))

(defthm logxor-natp
    (implies (and (natp i)
		  (natp j))
	     (natp (logxor i j)))
  :rule-classes (:type-prescription :rewrite))


(defthm logxor-bvecp
    (implies (and (bvecp x n)
		  (bvecp y n)
                  (natp n))
	     (bvecp (logxor x y) n)))

(defun logop-2-induct-g (x y)
  (declare (xargs :measure (+ (nfix (abs x)) (nfix (abs y)))))
  (if (and (integerp x) (integerp y))
      (if (and (or (equal x 0)
                   (equal x -1))
               (or (equal y 0)
                   (equal y -1)))
          t
        (logop-2-induct-g (fl (/ x 2)) (fl (/ y 2))))
    t))

(defun logop-2-n-induct (x y n)
  (if (zp n)
      (cons x y)
    (logop-2-n-induct (fl (/ x 2)) (fl (/ y 2)) (1- n))))

(defun logop-3-induct-g (x y z)
  (declare (xargs :measure (+ (nfix (abs x)) (nfix (abs y)) (nfix (abs z)))))
  (if (and (integerp x) (integerp y) (integerp z))
      (if (and (or (equal x 0)
                   (equal x -1))
               (or (equal y 0)
                   (equal y -1))
               (or (equal z 0)
                   (equal z -1)))
	  t
	(logop-3-induct-g (fl (/ x 2)) (fl (/ y 2)) (fl (/ z 2))))
    t))

(defthmd logand-fl-2-rewrite
    (implies (and (natp x)
		  (natp y))
	     (equal (fl (* 1/2 (logand x y)))
		    (logand (fl (* 1/2 x)) (fl (* 1/2 y))))))

(defthmd logior-fl-2-rewrite
    (implies (and (natp i)
		  (natp j))
	     (equal (fl (* 1/2 (logior i j)))
		    (logior (fl (* 1/2 i)) (fl (* 1/2 j))))))

(defthmd logxor-fl-2-rewrite
    (implies (and (natp i)
		  (natp j))
	     (equal (fl (* 1/2 (logxor i j)))
		    (logxor (fl (* 1/2 i)) (fl (* 1/2 j))))))

(defthm logior-not-0
    (implies (and (integerp x)
		  (integerp y)
		  (= (logior x y) 0))
	     (and (= x 0) (= y 0)))
  :rule-classes ())

(defthm logior-expt
    (implies (and (natp n)
		  (integerp x)
		  (bvecp y n))
	     (= (logior (* (expt 2 n) x) y)
		(+ (* (expt 2 n) x) y)))
  :rule-classes ()
  :hints (("Goal" :by logior-expt-g)))

(defthm logior-expt-2
    (implies (and (integerp x)
		  (integerp y)
		  (natp n))
	     (= (logior (* (expt 2 n) x)
			(* (expt 2 n) y))
		(* (expt 2 n) (logior x y))))
  :rule-classes ()
  :hints (("Goal" :by logior-expt-2-g)))


(defthm logand-bnd
    (implies (<= 0 x)
	     (<= (logand x y) x))
  :rule-classes :linear)

(defthm logand-expt
    (implies (and (integerp x)
		  (integerp y)
		  (natp n))
	     (= (logand (* (expt 2 n) x) y)
		(* (expt 2 n) (logand x (fl (/ y (expt 2 n)))))))
  :rule-classes ()
  :hints (("Goal" :by logand-expt-g)))

(defthmd bitn-logand
    (implies (and (integerp x)
		  (integerp y)
		  (integerp n))
	     (equal (bitn (logand x y) n)
		    (logand (bitn x n) (bitn y n))))
    :hints (("Goal" :use bitn_alt-logand)))


(defthmd bits-logand
    (implies (and (integerp x)
		  (integerp y)
		  (integerp i)
		  (integerp j))
	     (equal (bits (logand x y) i j)
		    (logand (bits x i j) (bits y i j))))
    :hints (("Goal" :use bits_alt-logand)))

(defthmd logand-bvecp-2
  (implies (and (natp n)
                (bvecp x (1+ n))
                (integerp y))
           (equal (logand x (bits y n 0))
                  (logand x y)))
  :hints (("Goal" :use ((:instance bits-logand (i n) (j 0))))))

(defthmd bitn-logior
    (implies (and (integerp x)
		  (integerp y)
		  (integerp n))
	     (equal (bitn (logior x y) n)
		    (logior (bitn x n) (bitn y n))))
    :hints (("Goal" :use bitn_alt-logior)))


(defthmd bits-logior
    (implies (and (integerp x)
		  (integerp y)
		  (integerp i)
		  (integerp j))
	     (equal (bits (logior x y) i j)
		    (logior (bits x i j) (bits y i j))))
    :hints (("Goal" :use bits_alt-logior)))


(defthmd bitn-logxor
    (implies (and (case-split (integerp x))
		  (case-split (integerp y))
		  (case-split (integerp n)))
	     (equal (bitn (logxor x y) n)
		    (logxor (bitn x n) (bitn y n))))
    :hints (("Goal" :use bitn_alt-logxor)))

(defthmd bits-logxor
  (implies (and (case-split (integerp x))
                (case-split (integerp y))
                (case-split (integerp i))
                (case-split (integerp j)))
           (equal (bits (logxor x y) i j)
                  (logxor (bits x i j) (bits y i j))))
    :hints (("Goal" :use bits_alt-logxor)))

(defthmd logand-expt-2
    (implies (and (integerp x)
		  (natp k))
	     (equal (logand x (expt 2 k))
		    (* (expt 2 k) (bitn x k))))
    :hints (("Goal" :use logand-expt-2-g)))

(defthmd logior-expt-3
    (implies (and (integerp x)
		  (natp k))
	     (equal (logior x (expt 2 k))
		    (+ x
		       (* (expt 2 k) 
			  (- 1 (bitn x k))))))
    :hints (("Goal" :use ((:instance logior-expt-3-g)))))

(defthmd logand-expt-3
    (implies (and (integerp x)
		  (natp n)
		  (natp k)
		  (< k n))
	     (equal (logand x (- (expt 2 n) (expt 2 k)))
		    (* (expt 2 k) (bits x (1- n) k))))
    :hints (("Goal" :use ((:instance logand-expt-3-g)))))

(defthmd logand-expt-4
    (implies (and (natp n)
		  (natp k)
		  (natp l)
		  (< l k)
		  (<= k n))
	     (equal (logand (- (1- (expt 2 n)) (expt 2 l)) (- (expt 2 n) (expt 2 k)))
		    (- (expt 2 n) (expt 2 k))))
    :hints (("Goal" :use ((:instance logand-expt-4-g)))))

(defthmd logand-shift
    (implies (and (integerp x)
		  (integerp y)
		  (natp k))
	     (equal (logand (* (expt 2 k) x)
			    (* (expt 2 k) y))
		    (* (expt 2 k) (logand x y)))))

(defthmd logxor-shift
    (implies (and (integerp x)
		  (integerp y)
		  (natp k))
	     (equal (logxor (* (expt 2 k) x)
			    (* (expt 2 k) y))
		    (* (expt 2 k) (logxor x y)))))

(defthmd logior-shift
    (implies (and (integerp x)
		  (integerp y)
		  (natp k))
	     (equal (logior (* (expt 2 k) x)
			    (* (expt 2 k) y))
		    (* (expt 2 k) (logior x y)))))

(defthmd fl-logand
  (implies (and (integerp x)
                (integerp y)
                (natp n)
                (natp k))
           (equal (fl (/ (logand x y) (expt 2 k)))
                  (logand (fl (/ x (expt 2 k))) (fl (/ y (expt 2 k)))))))

(defthmd fl-logior
  (implies (and (integerp x)
                (integerp y)
                (natp n)
                (natp k))
           (equal (fl (/ (logior x y) (expt 2 k)))
                  (logior (fl (/ x (expt 2 k))) (fl (/ y (expt 2 k)))))))

(defthmd fl-logxor
  (implies (and (integerp x)
                (integerp y)
                (natp n)
                (natp k))
           (equal (fl (/ (logxor x y) (expt 2 k)))
                  (logxor (fl (/ x (expt 2 k))) (fl (/ y (expt 2 k)))))))


;;;**********************************************************************
;;;                               LOGNOT
;;;**********************************************************************

(in-theory (disable lognot))

(defthmd lognot-def
    (implies (integerp x)
	     (equal (lognot x)
		    (1- (- x)))))

(defthmd bitn-lognot
    (implies (and (integerp x)
		  (integerp n)
		  (> n 0))
	     (not (equal (bitn (lognot x) n)
			 (bitn x n))))
    :hints (("Goal" :use bitn_alt-lognot)))

(defthmd logand-bitn-lognot-1
  (implies (and (integerp n)
                (integerp x)
                (integerp y))                
           (equal (logand (bitn (lognot x) n) (bitn y n))
                  (logand (lognot (bitn x n)) (bitn y n))))
  :hints (("Goal" :cases ((< n 0))
                  :use ((:instance bits-lognot (i n) (j n))
                        bitn-0-1
                        (:instance bitn-0-1 (x y))))))

(defthmd logand-bitn-lognot-alt
  (implies (and (integerp n)
                (integerp x)
                (integerp y))
           (equal (logand (bitn y n) (bitn (lognot x) n))
                  (logand (bitn y n) (lognot (bitn x n)))))
  :hints (("Goal" :cases ((< n 0))
                  :use ((:instance bits-lognot (i n) (j n))
                        bitn-0-1
                        (:instance bitn-0-1 (x y))))))

(defthmd bits-lognot
    (implies (and (natp i)
		  (natp j)
		  (<= j i)
		  (integerp x))
	     (equal (bits (lognot x) i j)
		    (- (1- (expt 2 (- (1+ i) j))) (bits x i j)))))

(defthmd bits-lognot-bits
  (implies (and (integerp x)
                (natp i)
                (natp j)
                (natp k)
                (natp l)
                (<= l k)
                (<= k (- i j)))
           (equal (bits (lognot (bits x i j)) k l)
                  (bits (lognot x) (+ k j) (+ l j))))
  :hints (("Goal" :in-theory (enable bits-lognot))))

(defthmd bits-lognot-bits-lognot
  (implies (and (integerp x)
                (natp i)
                (natp j)
                (natp k)
                (natp l)
                (<= l k)
                (<= k (- i j)))
           (equal (bits (lognot (bits (lognot x) i j)) k l)
                  (bits x (+ k j) (+ l j))))
  :hints (("Goal" :in-theory (enable bits-lognot-bits))))



(defthmd logand-bits-lognot
  (implies (and (integerp x)
                (integerp n)
                (bvecp y (1+ n)))
           (equal (logand y (bits (lognot x) n 0))
                  (logand y (lognot (bits x n 0)))))
  :hints (("Goal" :use ((:instance logand-bvecp-2 (x y) (y (lognot (bits x n 0)))))
                  :cases ((< n 0))
                  :in-theory (enable bits-lognot-bits))))

(defthmd lognot-shift
  (implies (and (integerp x)
                (natp k))
           (equal (lognot (* (expt 2 k) x))
		  (+ (* (expt 2 k) (lognot x))
		     (1- (expt 2 k))))))

(defthmd lognot-fl
  (implies (and (integerp x)
                (not (zp n)))
           (equal (lognot (fl (/ x n)))
                  (fl (/ (lognot x) n))))
  :hints (("Goal" :use ((:instance fl-m-n (m (- x))))
                  :in-theory (enable lognot))))                


;;;**********************************************************************
;;;                         Algebraic Properties
;;;**********************************************************************

(defthm lognot-lognot
    (implies (case-split (integerp i))
	     (equal (lognot (lognot i))
		    i)))

(defthm logand-x-0
    (equal (logand x 0) 0))

(defthm logand-0-y
    (equal (logand 0 y) 0))

(defthm logior-x-0
    (implies (integerp x)
	     (equal (logior x 0) x)))

(defthm logior-0-y
    (implies (integerp y)
	     (equal (logior 0 y) y)))

(defthm logxor-x-0
    (implies (integerp x)
	     (equal (logxor x 0) x)))

(defthm logxor-0-y
    (implies (integerp y)
	     (equal (logxor 0 y) y)))

(defthm logand-self
  (implies (case-split (integerp i))
           (equal (logand i i) i)))

(defthm logior-self
    (implies (case-split (integerp i))
	     (equal (logior i i) i)))

(defthm logxor-self
  (equal (logxor i i) 0))

(defthm logand-x-m1
    (implies (integerp x)
	     (equal (logand x -1) x)))

(defthm logand-m1-y
    (implies (integerp y)
	     (equal (logand -1 y) y)))

(defthm logand-x-1
    (implies (bvecp x 1)
	     (equal (logand x 1) x)))

(defthm logand-1-x
    (implies (bvecp x 1)
	     (equal (logand 1 x) x)))

(defthm logior-x-m1
    (implies (integerp x)
	     (equal (logior x -1) -1)))

(defthm logior-m1-y
    (implies (integerp y)
	     (equal (logior -1 y) -1)))

(defthm logior-1-x
  (implies (bvecp x 1)
           (equal (logior 1 x) 1)))

(defthm logior-x-1
  (implies (bvecp x 1)
           (equal (logior x 1) 1)))


(defthm logxor-m1
    (implies (integerp x)
	     (equal (logxor x -1)
		    (lognot x))))

(defthm logand-commutative
    (equal (logand j i) (logand i j)))

(defthm logior-commutative
    (equal (logior j i) (logior i j)))

(defthm logxor-commutative
    (equal (logxor j i) (logxor i j)))

(defthm logand-associative
    (equal (logand (logand i j) k)
           (logand i (logand j k))))

(defthm logior-associative
    (equal (logior (logior i j) k)
	   (logior i (logior j k))))

(defthm logxor-associative
    (equal (logxor (logxor i j) k)
	   (logxor i (logxor j k))))

(defthm logand-commutative-2
  (equal (logand j i k)
	 (logand i j k)))

(defthm logior-commutative-2
  (equal (logior j i k)
	 (logior i j k)))

(defthm logxor-commutative-2
  (equal (logxor j i k)
	 (logxor i j k)))

(defthmd lognot-logxor
    (and (equal (logxor (lognot i) j)
                (lognot (logxor i j)))
         (equal (logxor j (lognot i))
                (lognot (logxor i j)))))

(defthmd logior-logand
  (implies (and (integerp x)
                (integerp y)
                (integerp z))
           (equal (logior x (logand y z))
                  (logand (logior x y) (logior x z))))
  :hints (("Goal" :by logior-logand-g)))

(defthmd logand-logior
  (implies (and (integerp x)
                (integerp y)
                (integerp z))
    (equal (logand x (logior y z))
	   (logior (logand x y) (logand x z))))
  :hints (("Goal" :by logand-logior-g)))


(defthmd logior-logand-2
  (implies (and (integerp x)
                (integerp y)
                (integerp z))
    (equal (logand  (logior y z) x)
	   (logior (logand y x) (logand z x)))))

(defthmd log3
  (implies (and (integerp x)
                (integerp y)
                (integerp z))
    (equal (logior (logand x y) (logior (logand x z) (logand y z)))
	   (logior (logand x y) (logand (logxor x y) z)))))

(defthmd logxor-rewrite-2
  (implies (and (integerp x)
                (integerp y))
           (equal (logxor x y)
                  (logior (logand x (lognot y))
                          (logand y (lognot x)))))
  :hints (("Goal" :by logxor-rewrite-2-g)))