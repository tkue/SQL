-- Source
-- http://www.sql-server-helper.com/tips/tip-of-the-day.aspx?tkey=3934817c-1a03-4ac9-a0ba-55b2bfbaea0f&tkw=uses-of-the-stuff-string-function


-- Mask a Credit Card Number
DECLARE @CreditCardNumber        VARCHAR(20)
SET @CreditCardNumber = '4111111111111111'

SELECT STUFF(@CreditCardNumber, 1, LEN(@CreditCardNumber) - 4,
       REPLICATE('X', LEN(@CreditCardNumber) - 4)) AS [Output]

