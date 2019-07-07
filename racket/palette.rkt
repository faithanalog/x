#lang racket/base

(require binaryio)
(require binaryio/reader)

(struct pxl (r g b a))

(struct img (w h pxls))

(define (b-read-ff-pixel br)
  (pxl
    (b-read-be-uint br 2)
    (b-read-be-uint br 2)
    (b-read-be-uint br 2)
    (b-read-be-uint br 2)))

(define (read-ff in)
  (if
    (not (equal? "farbfeld" (read-string 8 in)))
    (img 0 0 '())
    (let*
      ([br (make-binary-reader in)] 
       [w (b-read-be-uint br 4)]
       [h (b-read-be-uint br 4)])
      (img w h
        (build-vector
          (* w h)
          (lambda (_) (b-read-ff-pixel br)))))))

(define (write-ff img out)
  (begin
    (write-string "farbfeld" out)
    (write-integer (img-w img) 4 #f out)
    (write-integer (img-h img) 4 #f out)
    (for
      ([p (in-vector (img-pxls img))])
      (begin
        (write-integer (pxl-r p) 2 #f out)
        (write-integer (pxl-g p) 2 #f out)
        (write-integer (pxl-b p) 2 #f out)
        (write-integer (pxl-a p) 2 #f out)))))

(define i
  (call-with-input-file
    "swirl.ff"
    (lambda
      (in)
      (read-ff in))))

(println (img-w i))
(println (img-h i))
(println (pxl-r (vector-ref (img-pxls i) 0)))

(call-with-output-file
    "swirl_out.ff"
    (lambda
      (out)
      (write-ff i out))
    #:mode 'binary
    #:exists 'truncate/replace)
