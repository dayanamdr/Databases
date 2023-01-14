use MusicRecords

--Procedures to simplify the process for adding specific tests, tables, views and for creating the connections between them
GO
CREATE OR ALTER PROCEDURE addToTables (@tableName VARCHAR(50)) AS
BEGIN
	IF @tableName IN (SELECT [Name] from [Tables]) 
	BEGIN
		PRINT 'Table already present in Tables'
		RETURN
	END

	IF @tableName NOT IN (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES)
	BEGIN
		PRINT 'Table not present in the database'
		RETURN
	END

	INSERT INTO [Tables] ([Name]) 
	VALUES
		(@tableName)
END

GO
CREATE OR ALTER PROCEDURE addToViews (@viewName VARCHAR(50)) AS
BEGIN
	IF @viewName IN (SELECT [Name] from [Views]) 
	BEGIN
		PRINT 'View already present in Views'
		RETURN
	END

	IF @viewName NOT IN (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS)
	BEGIN
		PRINT 'View not present in the database'
		RETURN
	END

	INSERT INTO [Views] ([Name]) 
	VALUES
		(@viewName)
END

GO
CREATE OR ALTER PROCEDURE addToTests (@testName VARCHAR(50)) AS
BEGIN
	IF @testName IN (SELECT [Name] from [Tests]) 
	BEGIN
		PRINT 'Test already present in Tests'
		RETURN
	END

	INSERT INTO [Tests] ([Name]) 
	VALUES
		(@testName)
END

-- connnects a table to a test in TestTables table
GO
CREATE OR ALTER PROCEDURE connectTableToTest (@tableName VARCHAR(50), @testName VARCHAR(50), @rows INT, @pos INT) AS
BEGIN
	IF @tableName NOT IN (SELECT [Name] FROM [Tables]) 
		BEGIN
			PRINT 'Table not present in Tables'
			RETURN
		END

	IF @testName NOT IN (SELECT [Name] FROM [Tests])
		BEGIN
			PRINT 'Test not present in Test'
			RETURN
		END

	IF EXISTS( -- check whether the given data is already in the table with the same position
		SELECT * 
		FROM TestTables T1 JOIN Tests T2 ON T1.TestID = T2.TestID
		WHERE T2.[Name] = @testName AND Position = @pos
	)
		BEGIN
			PRINT 'Position provided conflicts with previous positions'
			RETURN
		END

	INSERT INTO [TestTables] (TestID, TableID, NoOfRows, Position) 
	VALUES (
		(SELECT [Tests].TestID FROM [Tests] WHERE [Name] = @testName),
		(SELECT [Tables].TableID FROM [Tables] WHERE [Name] = @tableName),
		@rows,
		@pos
	)
END

-- connects a view with a test in TestViews table
GO
CREATE OR ALTER PROCEDURE connectViewToTest (@viewName VARCHAR(50), @testName VARCHAR(50)) AS
BEGIN
	IF @viewName NOT IN (SELECT [Name] FROM [Views]) 
		BEGIN
			PRINT 'View not present in Views'
			RETURN
		END

	IF @testName NOT IN (Select [Name] FROM [Tests]) 
		BEGIN
			PRINT 'Test not present in Tests'
			RETURN
		END

	INSERT INTO [TestViews] (TestID, ViewID)
	VALUES(
		(SELECT [Tests].TestID FROM [Tests] WHERE [Name] = @testName),
		(SELECT [Views].ViewID FROM [Views] WHERE [Name] = @viewName)
	)
END

-- Delete data from a table
GO
CREATE OR ALTER PROCEDURE deleteDataFromTable (@tableID INT) AS
BEGIN
	IF @tableID NOT IN (SELECT [TableID] FROM [Tables])
	BEGIN
		PRINT 'Table not present in Tables.'
		RETURN
	END
	DECLARE @tableName NVARCHAR(50) = (SELECT [Name] FROM [Tables] WHERE TableID = @tableID)
	PRINT 'Delete data from table ' + @tableName
	DECLARE @query NVARCHAR(100) = N'DELETE FROM ' + @tableName
	PRINT @query
	EXEC sp_executesql @query
END


-- Delete data from all the tables involved in a test
GO
CREATE OR ALTER PROCEDURE deleteDataFromAllTables (@testID INT) AS
BEGIN
	IF @testID NOT IN (SELECT [TestID] FROM [Tests])
	BEGIN
		PRINT 'Test not present in Tests.'
		RETURN
	END
	PRINT 'Delete data from all tables for the test ' + CONVERT(VARCHAR, @testID)
	DECLARE @tableID INT
	DECLARE @pos INT
	-- cursor to iterate through the tables in the descending order of their position
	DECLARE allTableCursorDesc CURSOR LOCAL FOR
		SELECT T1.TableID, T1.Position 
		FROM TestTables T1 
		INNER JOIN Tests T2 ON T2.TestID = T1.TestID
		WHERE T2.TestID = @testID
		ORDER BY T1.Position DESC

	OPEN allTableCursorDesc
	FETCH allTableCursorDesc INTO @tableID, @pos
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		EXEC deleteDataFromTable @tableID
		FETCH NEXT FROM allTableCursorDesc INTO @tableID, @pos
	END
	CLOSE allTableCursorDesc
	DEALLOCATE allTableCursorDesc
END

-- Insert data into a specific table
GO
CREATE OR ALTER PROCEDURE insertDataIntoTable (@testRunID INT, @testID INT, @tableID INT) AS
BEGIN
	IF @testID NOT IN (SELECT [TestID] FROM [Tests])
	BEGIN
		PRINT 'Test not present in Tests.'
		RETURN
	END

	IF @testRunID NOT IN (SELECT [TestRunID] FROM [TestRuns])
	BEGIN
		PRINT 'Test run not present in TestRuns.'
		RETURN
	END

	IF @tableID NOT IN (SELECT [TableID] FROM [Tables])
	BEGIN
		PRINT 'Table not present in Tables.'
		RETURN
	END

	DECLARE @startTime DATETIME = SYSDATETIME()
	DECLARE @tableName VARCHAR(50) = (
		SELECT [Name] 
		FROM [Tables] 
		WHERE TableID = @tableID
	)
	PRINT 'Insert data into table ' + @tableName
	DECLARE @numberOfRows INT = (
		SELECT [NoOfRows] 
		FROM [TestTables]
		WHERE TestID = @testID AND TableID = @tableID
	)
	-- generate random data in the table
	EXEC generateRandomDataForTable @tableName, @numberOfRows
	DECLARE @endTime DATETIME = SYSDATETIME()
	INSERT INTO TestRunTables(TestRunID, TableID, StartAt, EndAt)
	VALUES (@testRunID, @tableID, @startTime, @endTime)
END

-- Insert data into all the tables involved in a test
GO
CREATE OR ALTER PROCEDURE insertDataIntoAllTables (@testRunID INT, @testID INT) AS
BEGIN
	IF @testID NOT IN (SELECT [TestID] FROM [Tests])
	BEGIN
		PRINT 'Test not present in Tests.'
		RETURN
	END

	IF @testRunID NOT IN (SELECT [TestRunID] FROM [TestRuns])
	BEGIN
		PRINT 'Test run not present in TestRuns.'
		RETURN
	END

	PRINT 'Insert data in all the tables for the test ' + CONVERT(VARCHAR, @testID)
	DECLARE @tableID INT
	DECLARE @pos INT
	--cursor to iterate through the tables in ascending order of their position
	DECLARE allTableCursorAsc CURSOR LOCAL FOR
		SELECT T1.TableID, T1.Position
		FROM TestTables T1
		INNER JOIN Tests T2 ON T2.TestID = T1.TestID
		WHERE T1.TestID = @testID
		ORDER BY T1.Position ASC

	OPEN allTableCursorAsc
	FETCH allTableCursorAsc INTO @tableID, @pos
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC insertDataIntoTable @testRunID, @testID, @tableID
		FETCH NEXT FROM allTableCursorAsc INTO @tableID, @pos
	END
	CLOSE allTableCursorAsc
	DEALLOCATE allTableCursorAsc
END

-- Select data from a view
GO
CREATE OR ALTER PROCEDURE selectDataFromView (@viewID INT, @testRunID INT) AS
BEGIN
	IF @viewID NOT IN (SELECT [ViewID] FROM [Views])
	BEGIN
		PRINT 'View not present in Views.'
		RETURN
	END

	IF @testRunID NOT IN (SELECT [TestRunID] FROM [TestRuns])
	BEGIN
		PRINT 'Test run not present in TestRuns.'
		RETURN
	END

	DECLARE @startTime DATETIME = SYSDATETIME()
	DECLARE @viewName VARCHAR(100) = (
		SELECT [Name]
		FROM [Views]
		WHERE ViewID = @viewID
	)
	PRINT 'Selecting data from the view ' + @viewName
	DECLARE @query NVARCHAR(150) = N'SELECT * FROM ' + @viewName
	EXEC sp_executesql @query

	DECLARE @endTime DATETIME = SYSDATETIME()
	INSERT INTO TestRunViews(TestRunID, ViewID, StartAt, EndAt)
	VALUES (@testRunID, @viewID, @startTime, @endTime)
END

-- Select data from all the views
GO
CREATE OR ALTER PROCEDURE selectAllViews (@testRunID INT, @testID INT) AS
BEGIN
	IF @testID NOT IN (SELECT [TestID] FROM [Tests])
	BEGIN
		PRINT 'Test not present in Tests.'
		RETURN
	END

	IF @testRunID NOT IN (SELECT [TestRunID] FROM [TestRuns])
	BEGIN
		PRINT 'Test run not present in TestRuns.'
		RETURN
	END

	PRINT 'Selecting data from all the views from the test ' + CONVERT(VARCHAR, @testID)
	DECLARE @viewID INT
	--cursor to iterate through the views
	DECLARE selectAllViewsCursor CURSOR LOCAL FOR
		SELECT T1.ViewID FROM TestViews T1
		INNER JOIN Tests T2 ON T2.TestID = T1.TestID
		WHERE T1.TestID = @testID

	OPEN selectAllViewsCursor
	FETCH selectAllViewsCursor INTO @viewID
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		EXEC selectDataFromView @viewID, @testRunID
		FETCH NEXT FROM selectAllViewsCursor INTO @viewID
	END
	CLOSE selectAllViewsCursor
	DEALLOCATE selectAllViewsCursor
END

-- Run a test
GO
CREATE OR ALTER PROCEDURE runTest (@testID INT, @description VARCHAR(MAX)) AS
BEGIN
	IF @testID NOT IN (SELECT [TestID] FROM [Tests])
	BEGIN
		PRINT 'Test not present in Tests.'
		RETURN
	END

	PRINT 'Running test with the id ' + CONVERT(VARCHAR, @testID)
	INSERT INTO TestRuns([Description]) 
	VALUES (@description)
	DECLARE @testRunID INT = (
		SELECT MAX(TestRunID)
		FROM TestRuns
	)
	DECLARE @startTime DATETIME = SYSDATETIME()
	EXEC insertDataIntoAllTables @testRunID, @testID
	EXEC selectAllViews @testRunID, @testID
	DECLARE @endTime DATETIME = SYSDATETIME()
	EXEC deleteDataFromAllTables @testID

	UPDATE [TestRuns] SET StartAt = @startTime, EndAt = @endTime
	DECLARE @timeDifference INT = DATEDIFF(SECOND, @startTime, @endTime)
	PRINT 'The test with id ' + CONVERT(VARCHAR, @testID) + ' took ' + CONVERT(VARCHAR, @timeDifference) + ' seconds.'
END

-- Run all the tests
GO
CREATE OR ALTER PROCEDURE runAllTests AS
BEGIN
	DECLARE @testName VARCHAR(50)
	DECLARE @testID INT
	DECLARE @description VARCHAR(2000)
	--cursor to iterate through the tests
	DECLARE allTestsCursor CURSOR LOCAL FOR
		SELECT *
		FROM Tests

	OPEN allTestsCursor
	FETCH allTestsCursor INTO @testID, @testName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'Running ' + @testName
		SET @description = 'Test results for test with the ID ' + CAST(@testID AS VARCHAR(2))
		EXEC runTest @testID, @description
		FETCH NEXT FROM allTestsCursor INTO @testID, @testName
	END
	CLOSE allTestsCursor
	DEALLOCATE allTestsCursor
END

-- VIEWS
-- a view with a SELECT statement operating on one table
GO
CREATE OR ALTER VIEW awardsWithLengthNameBiggerThan10 AS
	SELECT A.award_name
	FROM Awards A
	WHERE len(A.award_name) > 5

--  a view with a SELECT statement operating on at least 2 tables
GO
CREATE OR ALTER VIEW realityShows AS
	SELECT S.show_name
	FROM Shows S INNER JOIN ShowTypes ST on S.id_showTypes = ST.id_showTypes

-- a view with a SELECT statement that has a GROUP BY clause and operates on at least 2 tables
-- GROUP BY and HAVING - gets the tour name for which the avg price is greater than 220
GO
CREATE OR ALTER VIEW toursWithAvgPriceGreaterThan220 AS
	SELECT T.tour_name AS TourName, AVG(TL.price) + 1000 AS TourAVGPrice
	FROM Tours T RIGHT JOIN ToursLocations TL ON T.tour_id=TL.tour_id 
	GROUP BY T.tour_name HAVING AVG(TL.price) > 220;
GO

-- CREATE THE TESTS

-- first test
-- a table with a single-column primary key 
-- a view with a SELECT statement operating on one table

EXEC addToViews 'awardsWithLengthNameBiggerThan10'
EXEC addToTests 'Test1'
EXEC addToTables 'Awards'
EXEC connectTableToTest 'Awards', 'Test1', 500, 1
EXEC connectViewToTest 'awardsWithLengthNameBiggerThan10', 'Test1'

-- second test
-- a view with a SELECT statement operating on at least two tables
-- a table with no foreign key (ArtistsInfo) and a single-column primary key and a table with a foreign key (Artists)


CREATE TABLE ShowTypes(
	id_showTypes INT PRIMARY KEY,
	showType VARCHAR(100)
);

CREATE TABLE Shows(
	id_show INT PRIMARY KEY,
	show_name VARCHAR(100),
	id_showTypes INT FOREIGN KEY REFERENCES ShowTypes(id_showTypes)
);

SELECT * FROM Shows;
SELECT * FROM ShowTypes;

DELETE FROM Shows;
DELETE FROM ShowTypes;


EXEC addToViews 'realityShows'
EXEC addToTests 'Test2'
EXEC addToTables 'ShowTypes'
EXEC connectTableToTest 'ShowTypes', 'Test2', 500, 1
EXEC addToTables 'Shows'
EXEC connectTableToTest 'Shows', 'Test2', 500, 2
EXEC connectViewToTest 'realityShows', 'Test2'

-- third test
-- a table with no foreign key and a single-column primary key, a table with a foreign key and a single-column primary key and a table with a multi-column primary key
-- a view with a SELECT statement that has a GROUP BY clause and operates on at least 2 tables
EXEC addToViews 'toursWithAvgPriceGreaterThan220'
EXEC addToTests 'Test3'
EXEC addToTables 'Tours'
EXEC connectTableToTest 'Tours', 'Test3', 500, 1
EXEC addToTables 'ToursLocations'
EXEC connectTableToTest 'ToursLocations', 'Test3', 500, 2
EXEC connectViewToTest 'toursWithAvgPriceGreaterThan220', 'Test3'

EXEC runAllTests

SELECT *
FROM [Views]

SELECT *
FROM [Tables]

SELECT *
FROM [Tests]

SELECT *
FROM [TestTables]

SELECT *
FROM [TestViews]

SELECT *
FROM [TestRuns]

SELECT *
FROM [TestRunTables]

SELECT *
FROM [TestRunViews]

DELETE FROM [TestRuns]
DELETE FROM [TestRunTables]
DELETE FROM [TestRunViews]
DELETE FROM [TestTables]
DELETE FROM [TestViews]
DELETE FROM [Tests]
DELETE FROM [Views]
DELETE FROM [Tables]

