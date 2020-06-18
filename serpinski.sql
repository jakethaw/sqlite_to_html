--
-- JT - 2020-06-08
--
-- Serpinski triangle
--

.param set $min_x       -310
.param set $max_x       310
.param set $min_y       -180
.param set $max_y       350

.param set $size        700
.param set $depth       5

CREATE TEMPORARY TABLE path (
  x  REAL,
  y  REAL,
  o1 TEXT,
  o2 INT
);

--
-- Draw a serpinski triangle
--
WITH
size(s, d) AS (
SELECT $size,
       $depth
),

border(x1, y1, x2, y2, x3, y3) AS (
SELECT -(s/2)*sqrt(3)/2, -(s/4),
       0.0, (s/2),
       (s/2)*sqrt(3)/2,-(s/4)
  FROM size
),

segments(i) AS (
VALUES (1), (2), (3)
),

cutout(id, depth, x1, y1, x2, y2, x3, y3) AS (
SELECT 1,
       1,
       (x1+x2)/2,
       (y1+y2)/2,
       (x1+x3)/2,
       (y1+y3)/2,
       (x2+x3)/2,
       (y2+y3)/2
  FROM border
UNION ALL
SELECT id || '.' || i,
       depth+1,
       CASE i
         WHEN 1 THEN (x1+x2)/2
         WHEN 2 THEN x1-(x3-x2)/2
         WHEN 3 THEN -x1-(x3-x2)/2
       END,

       CASE i
         WHEN 1 THEN y1+(y3-y2)/2
         WHEN 2 THEN (y2+y3)/2
         WHEN 3 THEN (y2+y3)/2
       END,

       CASE i
         WHEN 1 THEN (x1+x3)/2
         WHEN 2 THEN x1
         WHEN 3 THEN -x1
       END,

       CASE i
         WHEN 1 THEN (y1+y3)/2
         WHEN 2 THEN y2
         WHEN 3 THEN y2
       END,

       CASE i
         WHEN 1 THEN (x2+x3)/2
         WHEN 2 THEN x1+(x3-x2)/2
         WHEN 3 THEN -x1+(x3-x2)/2
       END,

       CASE i
         WHEN 1 THEN y1+(y3-y2)/2
         WHEN 2 THEN (y1+y2)/2
         WHEN 3 THEN (y2+y3)/2
       END

  FROM cutout
  JOIN segments
  JOIN size
 WHERE depth < d
 LIMIT 2000
)
INSERT INTO path
SELECT x1, y1, '0', 1
  FROM border
UNION ALL
SELECT x2, y2, '0', 2
  FROM border
UNION ALL
SELECT x3, y3, '0', 3
  FROM border
UNION ALL
SELECT x1, y1, id, 1
  FROM cutout
UNION ALL
SELECT x2, y2, id, 2
  FROM cutout
UNION ALL
SELECT x3, y3, id, 3
  FROM cutout
ORDER BY 3, 4
LIMIT 3*(($timer*50)%(power(2.8, $depth)));

--
-- OUTPUT
--
.output output.svg
SELECT printf('<svg width="%s" height="%s" style="background-color: white;">', Abs($max_x-$min_x), Abs($max_y-$min_y));
SELECT printf('<g transform="translate(%s %s)">', -$min_x, $max_y);

-- Draw path
SELECT printf('<path d="%s" stroke="darkblue" fill="orange"/>',
              Group_Concat(CASE o2
                             WHEN 1 THEN 'M' 
                             WHEN 2 THEN 'L'
                             WHEN 3 THEN 'L'
                           END 
                        || printf('%s %s', x, -y) 
                        || CASE o2
                             WHEN 3 THEN ' Z'
                             ELSE ''
                           END, ' '))
  FROM (SELECT *
          FROM path
         ORDER BY o1, o2);

SELECT '</g>';
SELECT '</svg>';