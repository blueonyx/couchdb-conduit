{-# LANGUAGE DeriveDataTypeable #-} 
{-# LANGUAGE OverloadedStrings #-} 

{- | CouchDB database methods.

> runCouch def {couchDB="my_db"} $ couchPutDb
> runCouch def {couchDB="my_new_db"} $ couchPutDb
-}

module Database.CouchDB.Conduit.DB (
    -- * Methods
    couchPutDB,
    couchPutDB_,
    couchDeleteDB,
    -- * Security
    couchSecureDB,
    -- * Replication
    couchReplicateDB
) where

import Control.Monad (void)

import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString as B
import qualified Data.Aeson as A

import qualified Network.HTTP.Conduit as H
import qualified Network.HTTP.Types as HT

import Database.CouchDB.Conduit.Internal.Connection 
            (MonadCouch(..), Path, mkPath)
import Database.CouchDB.Conduit.LowLevel (couch, couch', protect, protect')


-- | Create CouchDB database. 
couchPutDB :: MonadCouch m => 
       Path             -- ^ Database
    -> m ()
couchPutDB db = void $ couch HT.methodPut 
                            ( mkPath [db]) [] [] 
                            (H.RequestBodyBS B.empty)
                            protect'

-- | \"Don't care\" version of couchPutDb. Create CouchDB database only in its 
--   absence. For this it handles @412@ responses.
couchPutDB_ :: MonadCouch m => 
       Path             -- ^ Database
    -> m ()
couchPutDB_ db = void $ couch HT.methodPut 
                    (mkPath [db]) [] []
                    (H.RequestBodyBS B.empty) 
                    (protect [HT.status200, HT.status201, HT.status202, HT.status304, HT.status412] return) 

-- | Delete a database.
couchDeleteDB :: MonadCouch m => 
       Path             -- ^ Database
    -> m ()
couchDeleteDB db = void $ couch HT.methodDelete 
                    (mkPath [db]) [] []
                    (H.RequestBodyBS B.empty) protect' 

-- | Maintain DB security.
couchSecureDB :: MonadCouch m => 
       Path             -- ^ Database
    -> [T.Text]   -- ^ Admin roles 
    -> [T.Text]   -- ^ Admin names
    -> [T.Text]   -- ^ Readers roles 
    -> [T.Text]   -- ^ Readers names
    -> m ()       
couchSecureDB db adminRoles adminNames readersRoles readersNames = 
    void $ couch HT.methodPut 
            (mkPath [db, "_security"]) [] []
            reqBody protect' 
  where
    reqBody = H.RequestBodyLBS $ A.encode $ A.object [
            "admins" A..= A.object [ "roles" A..= adminRoles,
                                     "names" A..= adminNames ],
            "readers" A..= A.object [ "roles" A..= readersRoles,
                                     "names" A..= readersNames ] ]

-- | Database replication. 
--
--   See <http://guide.couchdb.org/editions/1/en/api.html#replication> for 
--   details.
couchReplicateDB :: MonadCouch m => 
       Path     -- ^ Source database. Path or URL 
    -> Path     -- ^ Target database. Path or URL 
    -> Bool             -- ^ Target creation flag
    -> Bool             -- ^ Continuous flag
    -> Bool             -- ^ Cancel flag
    -> m ()
couchReplicateDB source target createTarget continuous cancel = 
    void $ couch' HT.methodPost (const "/_replicate") [] []
            reqBody protect' 
  where
    reqBody = H.RequestBodyLBS $ A.encode $ A.object [
            "source" A..= source,
            "target" A..= target,
            "create_target" A..= createTarget,
            "continuous" A..= continuous,
            "cancel" A..= cancel ]

        
        
        
        
        
        
