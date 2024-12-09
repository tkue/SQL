
/* DESCRIPTION

Splits two parts (e.g. 'FirstName LastName')

*/
/* EXAMPLE

Whole_Part = 'FirstPart LastPart'

First_Part = 'FirstPart'
Last_Part = 'LastPart'
*/

First_Part = CASE WHEN CHARINDEX(' ', LTRIM(RTRIM(Whole_Part))) <> 0 THEN LEFT(Whole_part, CHARINDEX(' ', RTRIM(Whole_part)) - 1) END
,Last_Part = CASE WHEN CHARINDEX(' ', LTRIM(RTRIM(Whole_part))) <> 0 THEN RIGHT(Whole_part, CHARINDEX(' ', REVERSE(Whole_part)) - 1) END