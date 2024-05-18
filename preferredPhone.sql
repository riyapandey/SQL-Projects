/* PURPOSE: This program is to check if there's any preferred phone not set
   PROGRAM: q-chk-PHONE_preferredPhone.sql
   SERVER: PROD
   FREQUENCY: Weekly
   
   SOURCE TABLES:
   	elcn_phoneBase
   	contact
   
   FILE NAME: DQfix-PHONE-Update preferred Phone.csv
   	      DQfix-PHONE-Update preferred Phone-flag.csv
   
   PROCESS DOCUMENT FILE: Updaing Preferred Phone.docx
   	Documented full process with step by step instructions how to update preferred email in CRM
   ACTION:
   	1. Using the output file to set the elcn_preferr in Email Address Entity (elcn_emailAddressBase)
   	2. Set the person preferred emailaddress in Person Entity (contactBase)
   
   LAYOUT:
	   Email Address Entity
		elcn_emailAddressId
		elcn_preferred 			1

	   Person Entity
		elcn_personId			(elcn_personId)
		Preferred Email Address 	(elcn_emailAddressId)
		Email Address 1			(elcn_email)
*/

-- 1. Get all the person record doesn't have preferred phone set
WITH tmp AS (
    SELECT elcn_personId, elcn_phoneNumber, elcn_phoneId, elcn_preferred
	       , elcn_PhoneStatusIdName, createdon, modifiedon
	  FROM (SELECT elcn_personid, elcn_phoneNumber, elcn_phoneId, elcn_preferred
	               , elcn_PhoneStatusIdName, createdon, modifiedon,
	               ROW_NUMBER() OVER (PARTITION BY elcn_personId 
		                      ORDER BY elcn_preferred DESC,
				             CASE WHEN elcn_phoneTypeName = 'Cell Phone' THEN 1
				   	          WHEN elcn_phoneTypeName = 'Home' THEN 2
						  WHEN elcn_phoneTypeName = 'Business' THEN 3
						  WHEN elcn_phoneTypeName = 'Business Cell' THEN 4
						  WHEN elcn_phoneTypeName = 'Unknown' THEN 5
						  WHEN elcn_phoneTypeName LIKE '% Fax%' THEN 9
						  ELSE 6
						 END, 
									 modifiedon DESC) rn
	          FROM elcn_phone a
	         WHERE statecode=0 AND statuscode=1
         	   AND a.elcn_PhoneStatusIdName = 'Current'
			   AND a.elcn_endDate IS NULL
			) t
	  WHERE rn = 1
)
SELECT a.*
       , c.elcn_preferredphone, c.Telephone1, c.elcn_primaryId, c.fullname, c.elcn_primaryconstituentaffiliationidName
  INTO #aa_prefPhone
  FROM tmp a
  JOIN contact c
    ON a.elcn_personId = c.contactId
       AND c.statecode=0 AND c.statuscode=1
       AND c.elcn_personStatusIdName = 'Active'
 WHERE c.elcn_preferredphone IS NULL 
    OR LTRIM(RTRIM(a.elcn_phonenumber)) != LTRIM(RTRIM(c.Telephone1)); 

SELECT * FROM #aa_prefPhone;
    

-- 2. Use the temp table to generate the prefer flag to reset phone.elcn_preferred
--    1st query to retrieve all the ids not set to preferred
--    2nd query to retrieve all the ids in PhoneBase which set to preferred but it's not in aa_prefPhone
--FileName: DQfix-PHONE-Update preferred Phone-flag_yyyyMM.csv
SELECT elcn_phoneId, 'Yes'	preferred, CONCAT('DQfix-PHONE-Update_preferredphone', CONVERT(Date, getDate())) [List Name]
  FROM #aa_prefPhone
 WHERE elcn_preferred=0
/*UNION
SELECT a.elcn_phoneId, 0 preferred
  FROM #aa_prefPhone a, elcn_phone b
 WHERE a.elcn_personid = b.elcn_personid
   AND a.elcn_phoneId != b.elcn_phoneId
   AND b.elcn_PhoneStatusIdName = 'Current'
   AND b.elcn_preferred = 1; */

-- 3. Update prefer phone to Person Entity
---FileName: DQupd-Person-PreferPhone.csv
/*SELECT elcn_personId personPrimaryKey, elcn_phoneId phonePrimaryKey, elcn_phoneNumber phoneNumber
	FROM #aa_prefPhone
	WHERE elcn_preferred=0;
*/



