--
-- JT - 2020-06-08
--
-- Affine transform
--

.param set $min_x       -10.0
.param set $max_x       10.0
.param set $min_y       -10.0
.param set $max_y       10.0
.param set $scale       28

.param set $axis                1
.param set $axis_labels         1
.param set $ticks               1
.param set $tick_labels         1


CREATE TEMPORARY TABLE path (
  x REAL,
  y REAL
);

WITH
v(n,x,y,x_scale,y_scale,rotate) AS (
SELECT 1, 0, 2*$scale, 1, 1, -$timer*Pi()/250
UNION ALL
SELECT n+1, 0, 2*$scale, 0.97, 0.97, CASE WHEN n%7 IN (0) THEN -1 ELSE 1 END * -$timer*Pi()/250
  FROM v
 LIMIT 50
),

end_point(x, y) AS (
VALUES (0,0)
),

local_transform(n,xx,yx,xy,yy,x0,y0) AS (
SELECT n,
       x_scale * cos(rotate),
       x_scale * sin(rotate),
      -y_scale * sin(rotate),
       y_scale * cos(rotate),
       x * cos(rotate) - y * sin(rotate),
       x * sin(rotate) + y * cos(rotate)
  FROM v
),

global_transform(n,xx,yx,xy,yy,x0,y0) AS (
SELECT *
  FROM local_transform
 WHERE n = 1
UNION ALL
SELECT b.n,
       a.xx*b.xx + a.xy*b.yx,
       a.yx*b.xx + a.yy*b.yx,
       a.xx*b.xy + a.xy*b.yy,
       a.yx*b.xy + a.yy*b.yy,
       a.xx*b.x0 + a.xy*b.y0 + a.x0,
       a.yx*b.x0 + a.yy*b.y0 + a.y0
  FROM local_transform  b
  JOIN global_transform a ON b.n = a.n+1
)

INSERT INTO path
SELECT 0, 0 UNION ALL
SELECT xx*0 + xy*0 + x0,
       yx*0 + yy*0 + y0
  FROM global_transform
UNION ALL
SELECT xx*x + xy*y + x0,
       yx*x + yy*y + y0
  FROM global_transform, end_point
 WHERE n = (SELECT Max(n) FROM v);

--
-- OUTPUT
--
.output output.svg
SELECT printf('<svg width="%s" height="%s" style="background-color: white;">', Abs($max_x-$min_x)*$scale, Abs($max_y-$min_y)*$scale);
SELECT printf('<g transform="translate(%s %s)">', -$min_x*$scale, $max_y*$scale);

-- Draw axis
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
              Group_Concat(IIF(first, 'M', 'L') || printf('%s %s', x, -y), ' '),
              'red')
  FROM (SELECT *, rowid = 1 first
          FROM path
         WHERE rowid <> (SELECT Max(oid) FROM path)
         ORDER BY rowid);

SELECT printf('<circle cx="%s" cy="%s" r="8" stroke="red" stroke-width="2" fill="gold" />', x, -y)
  FROM path
 WHERE rowid = (SELECT Max(oid) FROM path);

SELECT '</g>';
SELECT '</svg>';