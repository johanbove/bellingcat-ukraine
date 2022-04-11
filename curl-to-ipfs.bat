:: http://steve-jansen.github.io/guides/windows-batch-scripting/part-2-variables.html
:: Saves the JSON files to IPFS
@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

:: script global variables
SET me=%~n0
SET parent=%~dp0
SET folder=export
SET event=https://ukraine.bellingcat.com/ukraine-server/api/ukraine
SET page1=%event%/export_events/deeprows
SET file1=%folder%\export_events.json
SET page2=%event%/export_associations/deeprows
SET file2=%folder%\export_associations.json
SET page3=%event%/export_sources/deepids
SET file3=%folder%\export_sources.json
SET log=%parent%\%me%.log
:: Generate the ipfs key with `ipfs key gen --type=rsa --size=2048 bellingcat_ukraine`
SET ipfskey=k2k4r8k7lcogpmkq9mkf3ykg1rexvhmxcinz5z91k8v49gbem6ivjp1v
SET ipfskeyName=bellingcat_ukraine

ECHO %me%: %date% %time% started...
ECHO --- >> %log%
ECHO %me%: %date% %time% started... >> %log%

curl %page1% > %file1%
curl %page2% > %file2%
curl %page3% > %file3%

SET size=0
call :filesize %file1%
ECHO file 1 size is %size% >> %log%
if %size%==0 goto :eof

call :filesize %file2%
ECHO file 2 size is %size% >> %log%
if %size%==0 goto :eof

call :filesize %file3%
ECHO file 3 size is %size% >> %log%
if %size%==0 goto :eof

ECHO "Files copied..."

:: copies the files in the folder as they appear on the original site
COPY /Y %file1% %folder%\export_events\deeprow >> %log%
COPY /Y %file2% %folder%\export_associations\deeprow >> %log%
COPY /Y %file3% %folder%\export_sources\deepid >> %log%

SET ipfshash='';
SET ipfsbase32='';
FOR /F "usebackq delims=" %%f IN (`ipfs add -q -r %folder%`) DO SET ipfshash=%%f
FOR /F "usebackq delims=" %%f IN (`ipfs cid base32 %ipfshash%`) DO SET ipfsbase32=%%f

ECHO CID: %ipfshash% >> %log%
ECHO https://%ipfsbase32%.ipfs.dweb.link >> %log%

ECHO %me%: Pinning... >> %log%
ipfs pin add %ipfshash% >> %log%

:: ECHO %me%: Pinning to Pinata >> %log%
:: Turned off in favor of web3.storage
@REM ipfs pin remote add --service=Pinata --name=%ipfskeyName% %ipfshash% >> %log%

ECHO %me%: Uploading files to Web3.storage...
:: See https://web3.storage/docs/examples/getting-started/
node C:\Users\johan\Projects\IPFS\web3-storage-quickstart\put-files.js --token=%WEB3_STORAGE_KEY_PC1% %folder% >> %log%

ECHO %me%: Publishing to IPNS key %ipfskeyName% ... >> %log%
ipfs name publish --key=%ipfskeyName% %ipfshash% >> %log%

ECHO %me%: Done! Check the log %log% for details.

:: Thank you https://stackoverflow.com/a/11479359
:: Set filesize of first argument in %size% variable, and return
:filesize
  set size=%~z1
  exit /b 0

:: force execution to quit at the end of the "main" logic
EXIT %ERRORLEVEL%