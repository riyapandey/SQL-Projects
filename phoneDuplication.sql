/* Purpose dedup phone number
*/
-- Check all the dup records with When & Who audit trail
-- DB: PROD
-- Total: 171,053/194,291/38,294

   SELECT a.elcn_name, b.phone,
          a.elcn_phoneTypeName, a.elcn_preferred,
          -- ISNULL(CONVERT(VARCHAR(15),a.elcn_endDate,111),'') elcn_endDate,
          a.elcn_endDate, 
          a.createdbyname, a.createdon, a.ModifiedByName, a.modifiedon,
          a.elcn_phoneId, a.elcn_personId
          , ROW_NUMBER() OVER (PARTITION BY a.elcn_personId, b.phone
                               ORDER BY a.elcn_preferred DESC,
                               c.elcn_telephonyPriority , a.createdON) rn
     INTO aa_phone_dup
     FROM elcn_phone a, elcn_phoneTypeBase c,
          (SELECT COUNT(*) total, elcn_personId
                  , au_unformattedPhoneNumber  phone
             FROM elcn_phoneBase
            WHERE statecode = 0 AND statuscode = 1
            GROUP BY elcn_personId, au_unformattedPhoneNumber
            HAVING COUNT(*)>1) b
     WHERE a.elcn_personID = b.elcn_personId
       AND a.au_unformattedPhoneNumber =b.phone
       AND a.statecode = 0 AND a.statuscode = 1
       AND a.elcn_phoneType = c.elcn_phoneTypeId
     ORDER BY a.elcn_personId, a.elcn_endDate DESC;
  
-- 2. Deactivate List
-- Total: 92,064/ 19,183
-- FILE: DQupd-PHONE_deactivate_YYYYMM.csv
   SELECT elcn_phoneID, 
		 'Inactive' Status,
		 'Inactive' Status_Reason,
		 CONCAT(CONVERT(DATE,GETDATE()),'_DQupd-PHONE_DeativatedDupPhone') [List Name]
          -- , elcn_phoneTypeName, elcn_name,  elcn_preferred
     FROM aa_phone_dup
    WHERE rn >1;

-- 3. Reset the end_date when rn=1 is not set 
-- Total: 9,045/ 59
-- FILE: DQupd-PHONE_reset endDate_YYYYMM.csv
    SELECT a.elcn_phoneId, -- a.phone, a.elcn_personId,
          MIN(b.elcn_endDate) endDate, CONCAT(CONVERT(DATE,GETDATE()),'_DQupd-PHONE_Enddate') [List Name]
     FROM aa_phone_dup a
     JOIN aa_phone_dup b 
       ON a.elcn_personID= b.elcn_personID AND a.phone=b.phone
          AND b.rn>1 AND b.elcn_endDate IS NOT NULL      
     WHERE a.rn =1  AND a.elcn_endDate IS NULL
     GROUP BY a.elcn_phoneId --, a.phone, a.elcn_personId
     ;          