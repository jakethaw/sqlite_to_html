--
-- JT - 2020-06-08
--
-- Dragon curve
--

.param set $min_x       -20.0
.param set $max_x       6.0
.param set $min_y       -6.0
.param set $max_y       12.0
.param set $scale       28

.param set $size        0.25
.param set $iterations  12

.param set $axis                1
.param set $axis_labels         1
.param set $ticks               1
.param set $tick_labels         1


CREATE TEMPORARY TABLE path (
  x REAL,
  y REAL
);

--
-- Draw a dragon curve
--
WITH 
p(n, x, y, turn, direction) AS (
SELECT 1, 0, 0, 'R', 'U'
UNION ALL
SELECT n+1,
       CASE direction
         WHEN 'R' THEN x+$size
         WHEN 'L' THEN x-$size
         ELSE x
       END,
       CASE direction
         WHEN 'U' THEN y+$size
         WHEN 'D' THEN y-$size
         ELSE y
       END,
       CASE 
         WHEN (((n & -n) << 1) & n) != 0 THEN 'L'
         ELSE 'R'
       END,
       CASE 
         WHEN direction='R' AND turn='R' THEN 'D'
         WHEN direction='R' AND turn='L' THEN 'U'
         WHEN direction='L' AND turn='R' THEN 'U'
         WHEN direction='L' AND turn='L' THEN 'D'
         WHEN direction='U' AND turn='R' THEN 'R'
         WHEN direction='U' AND turn='L' THEN 'L'
         WHEN direction='D' AND turn='R' THEN 'L'
         WHEN direction='D' AND turn='L' THEN 'R'
       END
  FROM p
 WHERE n < power(2, $iterations)+2
 LIMIT 100000
)
INSERT INTO path
SELECT x*$scale, (y-$size)*$scale
  FROM p
 WHERE n <> 1
 LIMIT 10*($timer%500);

--
-- OUTPUT
--
.output output.svg
SELECT printf('<svg width="%s" height="%s" style="background-color: white;">', Abs($max_x-$min_x)*$scale, Abs($max_y-$min_y)*$scale);
SELECT printf('<g transform="translate(%s %s)">', -$min_x*$scale, $max_y*$scale);

-- axis
SELECT printf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="black" />', $min_x*$scale, 0, $max_x*$scale, 0) WHERE $axis;
SELECT printf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="black" />', 0, -$min_y*$scale, 0, -$max_y*$scale) WHERE $axis;
-- axis labels
SELECT printf('<text x="%s" y="%s" style="font: bold 16px sans-serif;">x</text>', $max_x*$scale-15, 14) WHERE $axis_labels;
SELECT printf('<text x="%s" y="%s" style="font: bold 16px sans-serif;">y</text>', 10, -$max_y*$scale+20) WHERE $axis_labels;
-- ticks
WITH x_tick(x) AS(SELECT Round($min_x) UNION ALL SELECT x+1 FROM x_tick WHERE x<Round($max_x))
SELECT IIF($ticks, printf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="black" />', x*$scale, -4, x*$scale, +4), '')
    || IIF($tick_labels, printf('<text x="%s" y="%s" style="font:10px sans-serif;">%s</text>', x*$scale+2, 12, CAST(x AS INT)), '')
  FROM x_tick
 WHERE x <> 0
   AND ($ticks OR $tick_labels);
WITH y_tick(y) AS(SELECT Round($min_y) UNION ALL SELECT y+1 FROM y_tick WHERE y<Round($max_y))
SELECT IIF($ticks, printf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="black" />', -4, -y*$scale, +4, -y*$scale), '')
    || IIF($tick_labels, printf('<text x="%s" y="%s" style="font:10px sans-serif;">%s</text>', 4, -y*$scale-2, CAST(y AS INT)), '')
  FROM y_tick
 WHERE y <> 0
   AND ($ticks OR $tick_labels);

-- Draw path
SELECT printf('<path d="%s" stroke-width="2" stroke="%s" fill="none"/>',
              Group_Concat(IIF(first, 'M', 'L') || printf('%s %s', x, y), ' '),
              'darkblue')
  FROM (SELECT *, rowid = 1 first
          FROM path
         ORDER BY rowid);

SELECT '</g>';
SELECT '</svg>';