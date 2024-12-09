/* Convert String to Title/Proper Casing */
/*
	Source: http://sqlmag.com/t-sql/how-title-case-column-value

	Q. I have a column that stores names composed of varying numbers of words.
	For example, one, two, three, or even more words separated by a single space might constitute a name.
	I want to update the column values so that the first letter of each word in the name is uppercase and all the other letters are lowercase.

	A. Let's go to the Pubs database and use the title column in the titles table to help solve this problem.
	The solutions vary, depending on the release of SQL Server you're using.
	For SQL Server 7.0 and 6.5, you can use the following simple UPDATE query to make sure that only the first character in the title column values is uppercase:

	UPDATE titles
	  SET title =
	      UPPER(LEFT(title, 1)) +
	        LOWER(RIGHT(title, LEN(title) - 1))

	In the same batch, you can run a loop that iterates through all occurrences of a single space in the column. The UPDATE query uses the STUFF() function to replace the space and the character to the right of the space with the pound sign (#) character and the uppercase of the character to the right of the space. (You can use the # character if that character doesn't appear in the title column.) By using a character that isn't included in the column values, the loop proceeds to the next space in each iteration and continues until the last update affects no rows.

	UPDATE titles
	  SET title = REPLACE(title, '#', ' ')

	  In SQL Server 2000, you can solve this problem more efficiently by using a user-defined function (UDF). The UDF first turns all the input string's characters to lowercase and adds a single space to the beginning of the string. Next, the UDF forms a loop that iterates through all space occurrences in the string and makes the character to the right of the space uppercase by using the STUFF() function. Then, the function trims the first space it added and returns the revised string, as Listing 4 shows.

	  To test the UDF, first run it with a literal as an argument:

	SELECT  dbo.fn_title_case('jOhN gUtZoN dE lA mOtHe BoRgLuM')


	You should get the following output:

	John Gutzon De La Mothe Borglum


	You can use the UDF as follows to update the title column in the titles table:

	UPDATE titles
	  SET title = dbo. fn_title_case(title)
*/

/* USAGE */

-- OUTPUT
/*
	John Gutzon De La Mothe Borglum
*/
SELECT  dbo.fn_title_case('jOhN gUtZoN dE lA mOtHe BoRgLuM')

-- UPDATE COLUMN
UPDATE titles
  SET title = dbo. fn_title_case(title)

 ---------------------------------------------------------------------
 ---------------------------------------------------------------------



/* LISTING 3 */

-- LISTING 3: Code That Uses a Loop and the STUFF() Function (SQL Server 7.0 and 6.5) to
-- Title Case Words in a Column’s Values

WHILE @@rowcount > 0
  UPDATE titles
    SET title =
          STUFF(
            title,
            CHARINDEX(' ', title),
            2,
            '#' + UPPER(SUBSTRING(
                           title,
                           CHARINDEX(' ', title) + 1,
                           1)))
  WHERE CHARINDEX(' ', title) > 0


/* LISTING 4 */

-- LISTING 4: Code That Uses a UDF (SQL Server 2000) to Title Case Words in a Column’s
-- Values

CREATE FUNCTION dbo.fn_title_case
(
  @str AS varchar(100)
)
RETURNS varchar(100)
AS
BEGIN

  DECLARE
    @ret_str AS varchar(100),
    @pos AS int,
    @len AS int

  SELECT
    @ret_str = ' ' + LOWER(@str),
    @pos = 1,
    @len = LEN(@str) + 1

  WHILE @pos > 0 AND @pos < @len
  BEGIN
    SET @ret_str = STUFF(@ret_str,
                         @pos + 1,
                         1,
                         UPPER(SUBSTRING(@ret_str,@pos + 1, 1)))
    SET @pos = CHARINDEX(' ', @ret_str, @pos + 1)
  END

  RETURN RIGHT(@ret_str, @len - 1)

END

