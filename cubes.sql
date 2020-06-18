--
-- JT - 2020-06-08
--
-- Rotating cubes
--
-- https://en.wikipedia.org/wiki/3D_projection
--

.param set $min_x       -10.0
.param set $max_x       10.0
.param set $min_y       -10.0
.param set $max_y       10.0
.param set $scale       28

CREATE TABLE vars AS
SELECT 2 scale,
       $timer/2 a,
       $timer/2 b,
       $timer c,
       20 fl;

CREATE TABLE pts(x REAL, y REAL, z REAL);
INSERT
  INTO pts
VALUES (-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1),
       (-4,-4,-4),(-2,-4,-4),(-2,-4,-2),(-4,-4,-2),(-4,-2,-4),(-2,-2,-4),(-2,-2,-2),(-4,-2,-2),
       (-7,-7,-7),(-5,-7,-7),(-5,-7,-5),(-7,-7,-5),(-7,-5,-7),(-5,-5,-7),(-5,-5,-5),(-7,-5,-5);

CREATE TABLE fill_pts(fill_id INT, pt INT, PRIMARY KEY(fill_id, pt));
INSERT
  INTO fill_pts
VALUES (1,1),(1,2),(1,3),(1,4),
       (2,5),(2,6),(2,7),(2,8),
       (3,1),(3,2),(3,6),(3,5),
       (4,2),(4,3),(4,7),(4,6),
       (5,3),(5,4),(5,8),(5,7),
       (6,4),(6,1),(6,5),(6,8);
INSERT
  INTO fill_pts
SELECT fill_id+6, pt+8
  FROM fill_pts
 UNION ALL
SELECT fill_id+12, pt+16
  FROM fill_pts;

CREATE TABLE R AS
SELECT cos(b)*cos(c)                      [11], -cos(b)*sin(c)                     [12], sin(b)         [13],
       cos(a)*sin(c)+sin(a)*sin(b)*cos(c) [21], cos(a)*cos(c)-sin(a)*sin(b)*sin(c) [22], -sin(a)*cos(b) [23],
       sin(a)*sin(c)-cos(a)*sin(b)*cos(c) [31], sin(a)*cos(c)+cos(a)*sin(b)*sin(c) [32], cos(a)*cos(b)  [33]
  FROM vars;

CREATE TABLE A AS
  SELECT scale*(x*[11]+y*[21]+z*[31]) x,
         scale*(x*[12]+y*[22]+z*[32]) y,
         scale*(x*[13]+y*[23]+z*[33]) z
    FROM pts
    JOIN R
    JOIN vars;

CREATE TABLE B AS
SELECT fl*x/(fl-z) x, fl*y/(fl-z) y
  FROM A
  JOIN vars;

--
-- OUTPUT
--
.output output.svg
SELECT printf('<svg width="%s" height="%s" style="background-color: white;">', Abs($max_x-$min_x)*$scale, Abs($max_y-$min_y)*$scale);
SELECT printf('<g transform="translate(%s %s)">', -$min_x*$scale, $max_y*$scale);

-- Draw paths
SELECT printf('<path d="%s" stroke-width="1" stroke="black" fill="%s" fill-opacity="0.5"/>',
              Group_Concat(CASE vertex_id
                             WHEN 1 THEN 'M'
                             ELSE 'L'
                           END
                        || printf('%s %s', x*$scale, -y*$scale), ' '),
               colour)
  FROM (SELECT fp.fill_id,
               b.x,
               b.y,
               Row_Number() OVER (PARTITION BY fp.fill_id ORDER BY fp.rowid) vertex_id,
               CASE
                 WHEN fill_id BETWEEN 1 AND 6 THEN '#8080e6'
                 WHEN fill_id BETWEEN 7 AND 12 THEN '#80e680'
                 WHEN fill_id BETWEEN 13 AND 18 THEN '#e68080'
               END colour
          FROM fill_pts fp
          JOIN B        b  ON fp.pt = b.rowid) x
 GROUP BY fill_id
 ORDER BY (SELECT Min(a.z) 
             FROM fill_pts fp
             JOIN A        a  ON fp.pt = a.rowid
            WHERE fp.fill_id = x.fill_id);

SELECT '</g>';
SELECT '</svg>';