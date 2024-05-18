/* 
Purpose: This script is to deactivated Bounced emails and find the next preferred email for a person or constituent based on 
	     company's bussiness rule in order to clean up the database and improve the effectiveness of soliciation by ensuring accurate contact information.

Table_name: aa_enBounced
			 aa_bounced
			 contact
			 emailAddress
Running Frequency: Monthly
*/

--Step 1: Build a temp table to store all the current emails belonging to a person who's email was bounced, including the bounced email 
SELECT b.donorID, 
	   e.emailaddressId, 
	   e.email, 
	   e.preferred, 
	   e.au_enUsed, 
	   e.ModifiedOn, 
	   e.CreatedOn, 
	  (CASE WHEN e.email = b.EmailAddress THEN 1
            ELSE 0 END) AS bounced 
INTO aa_bounced
	FROM aa_enBounced AS b
 JOIN contact AS c ON b.DonorID = c.PrimaryID
	  AND c.StateCode=0 and c.StatusCode=1
	  AND c.elcn_PersonStatusIdName='Active'
 JOIN emailaddress AS e ON c.ContactId = e.personid
      AND e.statecode = 0 AND e.statuscode = 1 
	  AND e.EmailAddressStatusIdName = 'Current'
 ORDER BY b.donorId;

--Step 2: Priority a preferred email for a person based on business rule 
		-- and update the it's status to 'Preferred' in the system
SELECT emailaddressId, 
	   '1' preferred, 
	   CONCAT(CONVERT(Date, getDate()), 'ResetPreferredEmail') [List Name]
	FROM 
		(SELECT emailaddressId,
				donorId, 
				email,  
				preferred, 
				au_enUsed, 
				CreatedOn, 
				ModifiedOn, 
				ROW_NUMBER() OVER (PARTITION BY DonorId ORDER BY 
								   CASE WHEN email NOT LIKE '%best.edu%' THEN '1'
								        WHEN email LIKE '%@alumni%' THEN '2' 
								        WHEN email LIKE '%@best%' THEN '3'
										ELSE '4' END, 
									preferred DESC, 
									au_enUsed DESC, 
									CASE WHEN CreatedOn = ModifiedOn THEN CreatedOn
										 ELSE ModifiedOn END DESC) rn
				FROM aa_bounced
) t
 WHERE rn=1;

--Step 3: Spool a list of bounced email and deactived them in the database
SELECT emailaddressid, 
	   'Bounced' emailaddress_status, 
	   CONCAT(CONVERT(Date, getDate()), 'BouncedEmail') [List Name]
	FROM aa_bounced
 WHERE bounced = 1;