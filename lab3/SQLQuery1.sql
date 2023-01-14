


INSERT INTO ArtistsInfo VALUES(1, '1994-03-01', 'Canadian');
INSERT INTO ArtistsInfo VALUES(2, '1990-02-16', 'Canadian');


INSERT INTO Songs VALUES (1, 'Love yourself', 2);
INSERT INTO Songs VALUES (2, 'Sorry', 2);
INSERT INTO Songs VALUES (3, 'Peaches', 1);
INSERT INTO Songs VALUES (4, 'Anyone', 1);
INSERT INTO Songs VALUES (5, 'Lonely', 1);
INSERT INTO Songs VALUES (6, 'Boyfriend', 3);
INSERT INTO Songs VALUES (7, 'As long as you love me', 3);
INSERT INTO Songs VALUES (8, 'Starboy', 4);
INSERT INTO Songs VALUES (9, 'Reminder', 4);
INSERT INTO Songs VALUES (10, 'Die for you', 4);
INSERT INTO Songs VALUES (11, 'Blinding Lights', 5);
INSERT INTO Songs VALUES (12, 'Heartless', 5);
use MusicRecords

-- INSERT - the one that fails
--INSERT INTO Artists VALUES(7, 'Ariana Grande', 7); -- fails because there's no artist info with id 7 in the ArtistInfo table

-- UPDATE

-- UPDATE 1 - updates the nationality of 3 given Artists by ID to 'Canadian'
UPDATE ArtistsInfo 
SET nationality='Canadian' 
WHERE artist_info_id=1 OR artist_info_id=2 OR artist_info_id=3;

SELECT * FROM ArtistsInfo;

-- UPDATE 2 - assignes 'Justin Bieber' as an Artist to the first 7 songs
UPDATE ArtistsSongs
SET artist_id=1
WHERE song_id >= 1 AND song_id < 8;

SELECT * FROM ArtistsSongs;

-- UPDATE 3 - update the artist_info_id column for a given artist_id only if it's NULL
UPDATE Artists SET artist_info_id=3 WHERE artist_id=3 AND artist_info_id IS NULL;

SELECT * FROM Artists;


-- DELETE 1 - delete all the artists with the given names
DELETE FROM Artists WHERE full_name IN('Ariana Grande', 'Post Malone', 'Eminem');

SELECT * FROM Artists;

-- DELETE 2 - delete all the albums released in 2020.
DELETE FROM Albums WHERE release_date BETWEEN '2020-01-01' AND '2020-12-31';
SELECT * FROM Albums;

-- DELETE 3 - delete all the songs which title starts with S
DELETE FROM Songs WHERE title LIKE 'S%';



-- A
-- UNION - get all the artist whose nationality is Canadian or American

SELECT * FROM Artists;

SELECT A.full_name FROM Artists A, ArtistsInfo AI WHERE A.artist_id = AI.artist_info_id AND AI.nationality='Canadian'
UNION
SELECT A.full_name FROM Artists A, ArtistsInfo AI WHERE A.artist_id = AI.artist_info_id AND AI.nationality='American';

-- OR - get all the albums with genre R&B or Dance Pop

SELECT DISTINCT A.album_name 
FROM Albums A, AlbumsGenres AG, Genres G 
WHERE A.album_id = AG.album_id AND AG.genre_id IN (SELECT Genres.genre_id FROM Genres WHERE Genres.genre_name='R&B' OR Genres.genre_name='Dance Pop');
-- in the nested SELECT I get the IDs of the wanted genres

SELECT * FROM AlbumsGenres;

-- B
-- INTERSECT - get all the IDs of the artists who have at least one song registered in the Songs table

SELECT A.artist_id 
FROM Artists A
INTERSECT
SELECT S.artist_id FROM ArtistsSongs S;

-- IN - get all the names of the artists who have at least one song registered in the Songs table
SELECT A.full_name
FROM Artists A WHERE A.artist_id IN (SELECT S.artist_id FROM ArtistsSongs S);

-- C
-- EXCEPT - get all the IDs of the artists who don't have at least one song registered in the Songs table
SELECT A.artist_id 
FROM Artists A
EXCEPT
SELECT S.artist_id FROM ArtistsSongs S;

-- IN - get all the names of the artists who don't have at least one song registered in the Songs table
SELECT A.full_name
FROM Artists A WHERE A.artist_id NOT IN (SELECT S.artist_id FROM ArtistsSongs S);

-- D
-- INNER JOIN - gets all the artists who have released songs
SELECT DISTINCT A.full_name 
FROM Artists A INNER JOIN ArtistsSongs ASG 
ON A.artist_id=ASG.artist_id; 

-- LEFT JOIN - gets the Artists and their birth date an desc order
SELECT A.full_name, AI.birth_date 
FROM Artists A LEFT JOIN ArtistsInfo AI 
ON A.artist_info_id=AI.artist_info_id 
ORDER BY AI.birth_date DESC; 

-- RIGHT JOIN - get the name of the artists who have at least one song title starting with letter S (join in 3 tables)
SELECT DISTINCT A.full_name 
FROM Artists A RIGHT JOIN ArtistsSongs ASG
ON A.artist_id=ASG.artist_id
RIGHT JOIN Songs S
ON ASG.song_id=S.song_id WHERE S.title LIKE 'S%'
ORDER BY A.full_name DESC;

SELECT * FROM Songs;

-- FULL JOIN - get all the genres a given artist sings (Join on 6 tables)

SELECT G.genre_name
FROM Genres G FULL OUTER JOIN AlbumsGenres AG ON G.genre_id=AG.genre_id
			  FULL OUTER JOIN Albums A ON AG.album_id=A.album_id
			  FULL OUTER JOIN Songs S ON A.album_id=S.album_id
			  FULL OUTER JOIN ArtistsSongs ASG ON S.song_id=ASG.song_id
			  FULL OUTER JOIN Artists ART ON ASG.artist_id=ART.artist_id WHERE ART.full_name='Justin Bieber';

-- E - IN and subquery in WHERE
-- gets all the title songs of the Canadian artists
SELECT S.title FROM Songs S
INNER JOIN ArtistsSongs ASG ON S.song_id=ASG.song_id
WHERE ASG.artist_id IN (SELECT A.artist_id FROM Artists A LEFT JOIN ArtistsInfo AI ON A.artist_info_id=AI.artist_info_id WHERE AI.nationality='Canadian');

-- gets the top 3 songs from the albums released earlier than the 'Starboy' album
SELECT TOP 3 S.title FROM Songs S
WHERE S.album_id IN (SELECT A.album_id FROM Albums A
					 WHERE A.release_date < (SELECT Albums.release_date FROM Albums WHERE Albums.album_name='Starboy'))


-- F - EXISTS and subquery in WHERE
-- gets all the artists born after year 1990
SELECT A.full_name FROM Artists A
WHERE EXISTS (SELECT AI.birth_date FROM ArtistsInfo AI WHERE A.artist_info_id=AI.artist_info_id AND AI.birth_date >= '1990-01-01');

SELECT * FROM ArtistsInfo;

-- gets the top 2 albums with Pop genre
SELECT TOP 2 A.album_name FROM Albums A
WHERE EXISTS (SELECT AG.album_id FROM AlbumsGenres AG WHERE A.album_id=AG.album_id AND AG.genre_id=(SELECT G.genre_id FROM Genres G WHERE G.genre_name='Pop'));

SELECT * FROM Genres;
SELECT * FROM Albums;
SELECt * FROM AlbumsGenres;

-- G - subquery in FROM
-- get the R&B albums released released after 2020 inclusive
SELECT tempT.album_name
FROM (SELECT A.album_id, A.album_name, A.release_date FROM Albums A 
		LEFT JOIN AlbumsGenres AG ON A.album_id=AG.album_id 
		LEFT JOIN Genres G ON AG.genre_id=G.genre_id WHERE G.genre_name='R&B') 
AS tempT WHERE tempT.release_date >= '2020-01-01';

-- gets all the artists born before 1990
SELECT * 
FROM (SELECT A.full_name, AI.birth_date FROM Artists A INNER JOIN ArtistsInfo AI ON A.artist_info_id=AI.artist_info_id) 
AS tempT WHERE tempT.birth_date < '1990-01-01';


-- H
-- GROUP BY - count how many songs an artists has released
SELECT A.full_name AS ArtistName, COUNT(ASG.artist_id) AS NoSongs
FROM ArtistsSongs ASG LEFT JOIN Artists A ON ASG.artist_id=A.artist_id 
GROUP BY A.full_name;

-- GROUP BY and HAVING - gets the tour name for which the avg price is greater than 220
SELECT T.tour_name AS TourName, AVG(TL.price) + 1000 AS TourAVGPrice
FROM Tours T RIGHT JOIN ToursLocations TL ON T.tour_id=TL.tour_id 
GROUP BY T.tour_name HAVING AVG(TL.price) > 220;

-- GROUP BY and HAVING with subquery - get the sum of ticket prices by City which have a sum bigger than the one in New York
SELECT L.city AS City, SUM(TL.price) * 100 AS TotalTicketsSum
FROM Locations L INNER JOIN ToursLocations TL ON L.location_id=TL.location_id
GROUP BY L.city
HAVING SUM(TL.price) > (SELECT SUM(TLL.price) FROM ToursLocations TLL, Locations LL WHERE TLL.location_id=LL.location_id AND LL.city='New York');

-- GROUP BY and HAVING with subquery -
-- get the most expensive ticket for each tour which has the AVG greater than the AVG of 'Purpose Tour'
SELECT T.tour_name AS TourName, MAX(TL.price) + 1000 AS MaxShowPrice
FROM ToursLocations TL INNER JOIN Tours T ON TL.tour_id=T.tour_id
GROUP BY T.tour_name
HAVING AVG(TL.price) > (SELECT AVG(TL.price) FROM ToursLocations TL, Tours T WHERE TL.tour_id=T.tour_id AND T.tour_name='Purpose Tour');

-- I ANY&ALL
-- ANY - get the tour name for which it has at least one price equal to 125
SELECT T.tour_name FROM Tours T 
WHERE T.tour_id = ANY (SELECT TL.tour_id FROM ToursLocations TL WHERE TL.price = 125);
-- rewrite
SELECT T.tour_name FROM Tours T
WHERE T.tour_id IN (SELECT TL.tour_id FROM ToursLocations TL WHERE TL.price = 125);
--SELECT * FROM ToursLocations;

-- ANY - get all the genres name for each there exists a song 
SELECT G.genre_name FROM Genres G 
WHERE G.genre_id = ANY (SELECT AG.genre_id FROM AlbumsGenres AG);

-- ALL - get the genres for which there is no album released
SELECT G.genre_name FROM Genres G
WHERE G.genre_id <> ALL (SELECT AG.genre_id FROM AlbumsGenres AG);
-- rewrite
SELECT G.genre_name FROM Genres G
WHERE G.genre_id NOT IN (SELECT AG.genre_id FROM AlbumsGenres AG);

-- ALL - get the artists which have no song released
SELECT A.full_name FROM Artists A
WHERE A.artist_id <> ALL (SELECT ASG.artist_id FROM ArtistsSongs ASG);


