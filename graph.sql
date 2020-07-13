--
-- JT - 2020-05-30
--
-- Output SVG graph for given functions
--

.param set $min_x       -2.0
.param set $max_x       2.0
.param set $min_y       -2.0
.param set $max_y       2.0
.param set $sample_size 0.04
.param set $scale       140

.param set $axis                1
.param set $axis_labels         1
.param set $ticks               1
.param set $tick_labels         1
.param set $function_labels     1
.param set $intersections       1
.param set $intersection_labels 0

-------------------------------------------------------

-- Define x values for input sample size
CREATE TABLE x AS
SELECT $min_x+value*$sample_size x
  FROM generate_series(0, ($max_x-$min_x)/$sample_size);

-------------------------------------------------------
-- Functions
CREATE TABLE f(show, name, colour, x REAL, y REAL);
CREATE INDEX idx ON f(name, x, y, colour);
INSERT INTO f(
       show, name,                         colour,   x, y
)
SELECT 1,    'y = x',                      'blue',   x, x                              FROM x UNION ALL
SELECT 1,    'y = x^3',                    'green',  x, power(x,3)                     FROM x UNION ALL
SELECT 1,    'y = sin(5*x+t*π)*cos(x)',    'red',    x, sin(5*x+$timer*Pi())*cos(x)    FROM x UNION ALL
SELECT 0,    'y = cos(5x)',                'purple', x, cos(5*x)                       FROM x;
-------------------------------------------------------
--
-- Output SVG
--
.output output.svg
SELECT printf('<svg width="%s" height="%s" style="background-color: #EEEEEE;">', Abs($max_x-$min_x)*$scale, Abs($max_y-$min_y)*$scale);
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

-- Draw functions
SELECT printf('<text x="%s" y="%s" style="font: bold 13px sans-serif; fill: %s;">%s</text>', $min_x*$scale+10, -$max_y*$scale+20, 'black', 't = ' || Round($timer, 1))
 WHERE $function_labels;

WITH f_min_rowid AS (
SELECT name, Min(rowid) rowid, Row_Number() OVER (ORDER BY rowid) row
  FROM f 
 WHERE show
 GROUP BY name
)
SELECT printf('<path d="%s" stroke-width="2" stroke="%s" fill="none"/>',
              Group_Concat(IIF(first, 'M', 'L') || printf('%s %s', x*$scale, -y*$scale), ' '),
              colour)
    || IIF($function_labels, printf('<text x="%s" y="%s" style="font: bold 13px sans-serif; fill: %s;">%s</text>', $min_x*$scale+10, -$max_y*$scale+20*(row+1), colour, name), '')
  FROM (SELECT *, f.rowid = f_min_rowid.rowid first
          FROM f
          JOIN f_min_rowid USING (name)
         WHERE f.show
           AND (f.rowid % (1+1.0/($sample_size*$scale)) = 0 OR f.rowid = f_min_rowid.rowid)
         ORDER BY f.rowid)
 GROUP BY name
 ORDER BY row;

-- Circle the intersections
-- https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
WITH 
f_line AS (
SELECT name,
       x x1,
       Lead(x) OVER (win) x2,
       y y1,
       Lead(y) OVER (win) y2
  FROM f 
 WHERE show
WINDOW win AS (PARTITION BY name ORDER BY rowid)
),
f_t AS (
SELECT f1.x1, f1.x2,
       f1.y1, f1.y2,
       ((f1.x1 - f2.x1)*(f2.y1 - f2.y2)-(f1.y1 - f2.y1)*(f2.x1 - f2.x2))
      /((f1.x1 - f1.x2)*(f2.y1 - f2.y2)-(f1.y1 - f1.y2)*(f2.x1 - f2.x2)) t
  FROM f_line f1
  JOIN f_line f2 ON f1.x1 = f2.x1
                AND f1.name <> f2.name
 WHERE t BETWEEN 0 AND 1
),
f_intersect AS (
SELECT x1+t*(x2-x1) x,
       y1+t*(y2-y1) y
  FROM f_t
) 
SELECT IIF($intersections,
           printf('<circle cx="%s" cy="%s" r="5" stroke="black" stroke-width="1" fill="yellow" />',
                  x*$scale,
                  -y*$scale), '')
    || IIF($intersection_labels,
           printf('<text x="%s" y="%s" style="font:10px sans-serif;">(%s, %s)</text>',
                  x*$scale+5,
                  -y*$scale+14,
                  printf("%.3g", Round(x, 3)),
                  printf("%.3g", Round(y, 3))), '') 
  FROM f_intersect
 GROUP BY Round(x, 3), Round(y, 3)
 ORDER BY y, x;

SELECT '</g>';
SELECT '</svg>';