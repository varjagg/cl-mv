# cl-mv

Common lisp utilities for multiple values.

## Usage

The library currently exposes 5 symbols.

`mvpsetq` - `psetq` for multiple values.

```cl
(let (a b c d)
 (mvpsetq (a b) (values 1 2) (c d) (floor 19 5))
 (list a b c d))
;; -> (1 2 3 4)
```

`mvdo*` - `do*` for multiple values.

```cl
(mvdo* ((res nil (append res (list j k)))
        (i 1 (1+ i))
        ((j k) (floor 100 i) (floor 100 i)))
       ((> i 3) res))
;; -> (100 0 50 0 33 1)
```

`mvdo` - `do` for multiple values.

```cl
(mvdo ((res nil (append res (list j k)))
        (i 1 (1+ i))
        ((j k) (values -1 -1) (floor 100 i)))
       ((> i 3) res))
;; -> (-1 -1 100 0 50 0)
```

`mvlet*` - `let*` for multiple values.

```cl
(mvlet* (((i j) (values 1 2))
         (k 3)
         ((l) (values k))
         ((m n) (values k l)))
  (list i j k l m n))
;; -> (1 2 3 3 3 3)
```

`mvlet` - `let` for multiple values.

```cl
(let ((i 3) (j 2) (k 1))
  (mvlet (((i j) (values 5 4))
          ((k l) (values i j))
          (m k))
    (list i j k l m)))
;; -> (5 4 3 2 1)
```

## License

Be aware that big parts of the code come from Paul Grapham's Book [on lisp](http://www.paulgraham.com/onlisp.html). I couldn't find any Licence information for that code, so use at your own risk.

The remaining parts are licenced under vanilla MIT Licence.
