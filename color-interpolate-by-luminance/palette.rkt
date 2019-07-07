#lang racket

(require binaryio)
(require binaryio/reader)

(struct xyz (x y z a))
(struct srgb (r g b a))
(struct lrgb (r g b a))

(define (component-srgb-to-lrgb x)
  (if
    (<= x 0.0404482362771082)
    (/ x 12.92)
    (expt (/ (+ x 0.055) 1.055) 2.4)))

(define (component-lrgb-to-srgb x)
  (if
    (> x 0.0031308)
    (* 1.055 (- (expt x (/ 1.0 2.4)) 0.055))
    (* 12.92 x)))

(define (srgb-to-lrgb p)
  (lrgb
    (component-srgb-to-lrgb (srgb-r p))
    (component-srgb-to-lrgb (srgb-g p))
    (component-srgb-to-lrgb (srgb-b p))
    (srgb-a p)))

(define (lrgb-to-srgb p)
  (srgb
    (component-lrgb-to-srgb (lrgb-r p))
    (component-lrgb-to-srgb (lrgb-g p))
    (component-lrgb-to-srgb (lrgb-b p))
    (lrgb-a p)))

(define (lerp a b x)
  (+ (* a (- 1.0 x)) (* b x)))

(define (color-to-int-clamped x)
  (if
    (< x 0)
    (0)
    (if
      (> x 1)
      (1)
      (exact-round (* x 65535.0)))))

(define (lrgb-to-xyz p)
  (let
    ([w (/ 1.0 0.17697)])
    (xyz
      (* w (+ (* 0.49000 (lrgb-r p)) (* 0.31000 (lrgb-g p)) (* 0.20000 (lrgb-b p))))
      (* w (+ (* 0.17697 (lrgb-r p)) (* 0.81240 (lrgb-g p)) (* 0.01063 (lrgb-b p))))
      (* w (+ (* 0.00000 (lrgb-r p)) (* 0.01000 (lrgb-g p)) (* 0.99000 (lrgb-b p))))
      (lrgb-a p))))

(define (xyz-to-lrgb p)
  (lrgb
    (- (- (* 0.41847 (xyz-x p)) (* 0.15866 (xyz-y p))) (* 0.082835 (xyz-z p)))
    (+ (+ (* -0.091169 (xyz-x p)) (* 0.25243 (xyz-y p))) (* 0.015708 (xyz-z p)))
    (+ (- (* 0.00092090 (xyz-x p)) (* 0.0025498 (xyz-y p))) (* 0.17860 (xyz-z p)))
    (xyz-a p)))

(define (lrgb-to-y-normalized p)
  (+ (* 0.17697 (lrgb-r p)) (* 0.81240 (lrgb-g p)) (* 0.01063 (lrgb-b p))))

(struct img (w h pxls))

(define (palettize-pixel dark-xyz light-xyz in-srgb)
  (let*
    ([sf (lrgb-to-y-normalized (srgb-to-lrgb in-srgb))]
     [out-xyz
       (xyz
         (lerp (xyz-x dark-xyz) (xyz-x light-xyz) sf)
         (lerp (xyz-y dark-xyz) (xyz-y light-xyz) sf)
         (lerp (xyz-z dark-xyz) (xyz-z light-xyz) sf)
         (srgb-a in-srgb))]
     [out-srgb (lrgb-to-srgb (xyz-to-lrgb out-xyz))])
    out-srgb))

(define (palettize dark-srgb light-srgb i)
  (let
    ([dark (lrgb-to-xyz (srgb-to-lrgb dark-srgb))]
     [light (lrgb-to-xyz (srgb-to-lrgb light-srgb))])
    (begin
      (vector-map!
        (lambda (in-srgb)
          (palettize-pixel dark light in-srgb))
        (img-pxls i)))))

(define (b-read-ff-pixel br)
  (srgb
    (/ (b-read-be-uint br 2) 65535.0)
    (/ (b-read-be-uint br 2) 65535.0)
    (/ (b-read-be-uint br 2) 65535.0)
    (/ (b-read-be-uint br 2) 65535.0)))

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
        (write-integer (color-to-int-clamped (srgb-r p)) 2 #f out)
        (write-integer (color-to-int-clamped (srgb-g p)) 2 #f out)
        (write-integer (color-to-int-clamped (srgb-b p)) 2 #f out)
        (write-integer (color-to-int-clamped (srgb-a p)) 2 #f out)))))

(define i
  (call-with-input-file
    "swirl.ff"
    (lambda
      (in)
      (read-ff in))))


(println (img-w i))
(println (img-h i))
(println (srgb-r (vector-ref (img-pxls i) 0)))
(palettize (srgb 0.0 0.0 0.0 1.0) (srgb 1.0 1.0 1.0 1.0) i)
(println "palettized")

(call-with-output-file
    "swirl_out.ff"
    (lambda
      (out)
      (write-ff i out))
    #:mode 'binary
    #:exists 'truncate/replace)
