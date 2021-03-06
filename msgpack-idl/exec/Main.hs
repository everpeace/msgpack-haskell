{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE RecordWildCards #-}

import Control.Exception
import Data.Version
import System.Console.CmdArgs
import System.Directory
import Text.Peggy

import Language.MessagePack.IDL
import qualified Language.MessagePack.IDL.CodeGen.Haskell as Haskell
import qualified Language.MessagePack.IDL.CodeGen.Cpp as Cpp
import qualified Language.MessagePack.IDL.CodeGen.Ruby as Ruby
import qualified Language.MessagePack.IDL.CodeGen.Java as Java
import qualified Language.MessagePack.IDL.CodeGen.Php as Php
import qualified Language.MessagePack.IDL.CodeGen.Python as Python
import qualified Language.MessagePack.IDL.CodeGen.Perl as Perl

import Paths_msgpack_idl

data MPIDL
  = Haskell
  | Cpp
    { output_dir :: FilePath
    , namespace :: String
    , pficommon :: Bool
    , filepath :: FilePath }
  | Ruby
    { output_dir :: FilePath
    , modules :: String
    , filepath :: FilePath }
  | Java
    { output_dir :: FilePath
    , package :: String
    , filepath :: FilePath
    }
  | Php
    { output_dir :: FilePath
    , filepath :: FilePath
    }
  | Python
    { output_dir :: FilePath
    , filepath :: FilePath
    }
  | Perl
    { output_dir :: FilePath
    , namespace :: String
    , filepath :: FilePath }
  deriving (Show, Eq, Data, Typeable)

main :: IO ()
main = do
  conf <- cmdArgs $
    modes [ Haskell
          , Cpp { output_dir = def
                , namespace = "msgpack"
                , pficommon = False
                , filepath = def &= argPos 0
                }
          , Ruby { output_dir = def
                 , modules = "MessagePack"
                 , filepath = def &= argPos 0
                 }
          , Java { output_dir = def
                 , package = "msgpack"
                 , filepath = def &= argPos 0
                 }
          , Php { output_dir = def
                , filepath = def &= argPos 0
                }
          , Python { output_dir = def
                   , filepath = def &= argPos 0
                   }
          , Perl { output_dir = def
                , namespace = "msgpack"
                , filepath = def &= argPos 0
                }
          ]
    &= help "MessagePack RPC IDL Compiler"
    &= summary ("mpidl " ++ showVersion version)

  compile conf

compile :: MPIDL -> IO ()
compile conf = do
  espec <- parseFile idl (filepath conf)
  case espec of
    Left err -> do
      print err
    Right spec -> do
      print spec
      case conf of
        Cpp {..} -> do
          withDirectory output_dir $ do
            Cpp.generate (Cpp.Config filepath namespace pficommon) spec
        
        Java {..} -> do
          withDirectory (output_dir ++ "/" ++ package) $ do
            Java.generate (Java.Config filepath package) spec

        Perl {..} -> do
          withDirectory output_dir $ do
            Perl.generate (Perl.Config filepath namespace) spec

        Php {..} -> do
          withDirectory (output_dir) $ do
            Php.generate (Php.Config filepath) spec
 
        Python {..} -> do
          withDirectory (output_dir) $ do
            Python.generate (Python.Config filepath) spec
 
        Ruby {..} -> do
          withDirectory (output_dir) $ do
            Ruby.generate (Ruby.Config filepath modules) spec

withDirectory :: FilePath -> IO a -> IO a
withDirectory dir m = do
  createDirectoryIfMissing True dir
  bracket
    getCurrentDirectory
    setCurrentDirectory
    (\_ -> setCurrentDirectory dir >> m)
