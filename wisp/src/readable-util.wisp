(ns choc.readable.readable-util
  (:require [wisp.ast :refer [symbol keyword]]
            [wisp.sequence :refer [cons conj list list? seq vec empty?
                                       count first second third rest last
                                       butlast take drop repeat concat reverse sequential?
                                       sort map filter reduce assoc]]
            [wisp.runtime :refer [str = dictionary]]
            [wisp.compiler :refer [self-evaluating? compile macroexpand
                                       compile-program install-macro]]
            [wisp.reader :refer [read-from-string]] 
            [esprima :as esprima]
            [underscore :refer [has]]
            [util :refer [puts inspect]]))

(defn to-set [col] 
  (let [pairs (reduce (fn [acc item] (concat acc [item true])) [] col)]
    (apply dictionary (vec pairs))))

(defn set-incl? [set key]
  (.hasOwnProperty set key))

(defn pp [form] (puts (inspect form null 100 true)))

(defn transpile [& forms] (compile-program forms))

(defn flatten-once 
  "poor man's flatten"
  [lists] (reduce (fn [acc item] (concat acc item)) lists))

(defn partition
  "Returns a lazy sequence of lists of n items each, at offsets step
  apart. If step is not supplied, defaults to n, i.e. the partitions
  do not overlap. If a pad collection is supplied, use its elements as
  necessary to complete last partition upto n items. In case there are
  not enough padding elements, return a partition with less than n items."
  ([n coll]
     (partition n n coll))
  ([n step coll]
     (loop [result []
            items coll]
       (let [group (take n items)]
         (if (= n (count group))
           (recur (conj result group)
                  (drop step items))
           result))))
  ([n step pad coll]
   (partition n step (concat coll pad))))

(defn parse-js 
  "parses a string code of javascript into a parse tree. Returns an array of the
statements in the body"
  ([code] (parse-js code {:range true :loc true}))
  ([code opts]
     (let [program (.parse esprima code opts)]
       (:body program))))

;; (defmacro appendify-form 
;;   ; given ("a" "b" "c" "d")
;;   ; expands to (+ (+ (+ "a" "b") "c") "d")
;;   [items] 
;;   `(first 
;;     (reduce (fn [acc item] 
;;               (list (cons `+ (concat acc (list item))))) 
;;             (list (first ~items)) (rest ~items))))

;(print (.to-string (appendify-form `("a" "b" ("hi" "mom" "person") "c" "d"))))

;; (defn bob [forms]
;;   (bob (first forms)))

;; (install-macro :bob bob)

;; (print (.to-string (bob `("a" "b" ("hi" "mom" "person") "c" "d"))))

(defmacro when
  "Evaluates test. If logical true, evaluates body in an implicit do."
  [test & body]
  (list 'if test (cons 'do body)))

;; (defn bar [] "hello")
;; (defmacro foo [form]
;;   (print (bar))
;;   form)
;; (foo "bam")

;; (defn foo [] 1)

;; (defmacro condp [pred expr & clauses]
;;   (reduce 
;;    (fn [acc clause] 
;;      (let [group (first acc)
;;            form (rest acc)]
;;        (if (= (count group) 1)
;;          (cons (cons (first clause) group) form)
;;          (list 'if (cons pred (cons expr (list clause)))))))
;;    (list)
;;    clauses)
;;   )

;;   ;; (if (not (empty? clauses))
;;   ;;   (list 'if (cons pred (cons expr (list (first clauses))))
;;   ;;         (second clauses)
;;   ;;         (list 'condp pred expr)))

;;   ;; (when (not (empty? clauses))
;;   ;;   (list if `(pred expr (first clauses))
;;   ;;         (second clauses)
;;   ;;         (condp (cons pred (cons expr (rest (rest clauses)))))))
;;   )


; given ("a" "b" "c" "d")
; expands to (+ (+ (+ "a" "b") "c") "d")
; (print (.to-string (appendify-form `("a" "b" ("c" "d" "e" ("f" "g")) "h"))))
(defn appendify-form-old
  [items]
  (first
   (reduce (fn [acc item]
             (list (cons `+
                         (concat acc
                                 (if (list? item)
                                   (list (appendify-form item))
                                   (list item))))))
           (list (first items)) (rest items))))

(defn appendify-form
  [items] 
  (if (= (first items) `fn) 
    (list items)
    (let [head (first items)
          prefix (if (list? head)
                   (appendify-form head)
                   head)
          results (first 
                   (reduce (fn [acc item] 
                             (list (cons `+ 
                                         (concat acc 
                                                 (if (list? item)
                                                   (list (appendify-form item))
                                                   (list item)))))) 
                           (list prefix) (rest items)))]
      results)))


(defn appendify-to-str
  "given a nested list, concats those items together"
  [items] 
  (reduce (fn [acc item] 
            (+ acc 
               (if (list? item)
                 (appendify-to-str item)
                 item))) 
          ""
          items))


;; (defn appendify-list [source]
;;   (loop [result []
;;          list source]
;;     (if (empty? list)
;;       result
;;       (recur
;;         (do (.push result (first list)) result)
;;         (rest list)))))


