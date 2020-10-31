import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
import 'package:abbys/data/init_db.dart';
import 'package:abbys/data/version.dart';
import 'package:path/path.dart';

import 'package:flutter_archive/flutter_archive.dart';
import 'package:tweetnacl/tweetnacl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as driveV3;
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'GoogleAuthClient.dart';

import 'package:crypto/crypto.dart';

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

const ABYSS_FILE_NAME = "abbys-data.$ABYSS_VERSION.json";
const ABYSS_KEY_NAME = "abbys-key.$ABYSS_VERSION.json";
const ABYSS_FOLDER = "Abbyss";
const ABYSS_ZIP_NAME = "abbys.zip";
const ABYSS_BACKUP_FOLDER = "abyss_backup";
final printException =
    (e, s) => {print("Exception $e"), print("StackTrace $s")};

class AuthRequest {
  final driveV3.DriveApi driver;
  final GoogleAuthClient client;

  AuthRequest(this.driver, this.client);
}

//https://morioh.com/p/67f2eae3adf3
class DbService {
  Uint8List _publicKey;
  Uint8List _secretKey;
  bool loginFailed = false;
  bool isLoading = false;
  String _userPassword;
  AuthRequest _requestInfo;
  bool _dataIsValid = true;
  setUserPassword(String password) {
    _userPassword = password;
  }

  _debug(String msg, int level) {
    print(msg.padLeft(level, '***'));
  }

  Future<void> _debugFile(File file) async {
    final size = await file.length();
    _debug("${file.path} size $size}", 1);
  }

  _password(String password) {
    String hash = generateMd5(password);
    List<int> list = hash.codeUnits;
    Uint8List bytes = Uint8List.fromList(list);
    String hex = TweetNaclFast.hexEncodeToString(bytes);
    return TweetNaclFast.hexDecode(hex);
  }

  /*
    final ciphertext = _encryptMessage("test", "1234567");
    print(_decryptMessage(ciphertext, "1234567"));
   */
  _encryptMessage(String message, String password) {
    final box = SecretBox(_password(password));
    final msgParamsUInt8Array = Uint8List.fromList(utf8.encode(message));
    final encryptedMessage = box.box(msgParamsUInt8Array);
    return base64.encode(encryptedMessage);
  }

  _decryptMessage(String emessage, String password) {
    final box = SecretBox(_password(password));
    final message = box.open(base64.decode(emessage));
    return utf8.decode(message);
  }

  _decryptData(Uint8List data, String password) {
    final box = SecretBox(_password(password));
    final message = box.open(data);
    return message;
  }

  _encryptData(Uint8List data, String password) {
    final box = SecretBox(_password(password));
    final msgParamsUInt8Array = Uint8List.fromList(data);
    final encryptedMessage = box.box(msgParamsUInt8Array);
    return encryptedMessage;
  }

  Future<AuthRequest> get _request async {
    _debug('_request[start]', 1);
    if (_requestInfo != null) {
      return _requestInfo;
    }
    if (loginFailed) return null;
    loginFailed = true;
    final googleSignIn =
        signIn.GoogleSignIn.standard(scopes: [driveV3.DriveApi.DriveScope]);
    final signIn.GoogleSignInAccount account = await googleSignIn.signIn();
    print("User account $account");
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = driveV3.DriveApi(authenticateClient);
    loginFailed = false;
    _requestInfo = AuthRequest(driveApi, authenticateClient);
    return _requestInfo;
  }

  Future<driveV3.File> _getFolder(AuthRequest request) async {
    return _getFolderByName(request, ABYSS_FOLDER);
  }

  Future<driveV3.File> _getFolderByName(
      AuthRequest request, String name) async {
    _debug('_getFolder[start]', 1);
    try {
      String query = "mimeType='application/vnd.google-apps.folder' ";
      query += "and name='$name' ";
      final folders = await request.driver.files.list(q: query);
      if (folders.files.length > 0) return folders.files[0];
      driveV3.File fileMetadata = new driveV3.File();
      fileMetadata.name = name;
      fileMetadata.mimeType = "application/vnd.google-apps.folder";

      driveV3.File file = await request.driver.files.create(fileMetadata);
      return file;
    } catch (e, s) {
      printException(e, s);

      return null;
    }
  }

  Future<String> uploadToFolder(String folderName, File file) async {
    _debug('uploadToFolder[start]', 1);
    final path = await _localPath;
    final fileTmp = File('$path/${ABYSS_FILE_NAME}_tmp.bin');
    try {
      final request = await _request;
      if (loginFailed) return null;
      final bytes = await file.readAsBytes();
      final content = _userPassword != null
          ? _encryptData(bytes, _userPassword)
          : base64.encode(bytes);

      await fileTmp.writeAsBytes(content);

      String mediaName = basename(file.path);
      driveV3.File folder = await _getFolderByName(request, folderName);
      _debug('uploadToFolder[driveV3.File]', 2);
      final fileToUpload = new driveV3.File();
      fileToUpload.name = mediaName;
      _debug('uploadToFolder[_getFileId]', 2);
      fileToUpload.parents = [folder.id];
      _debug('uploadToFolder[driveV3.Media]', 2);
      final media = new driveV3.Media(fileTmp.openRead(), fileTmp.lengthSync());
      _debug('uploadToFolder[fileToUpload]', 2);
      final response =
          await request.driver.files.create(fileToUpload, uploadMedia: media);
      _debug('uploadToFolder[end="$mediaName"]:${response.id}', 1);
      return response.id;
    } catch (e, s) {
      printException(e, s);
    }
    await fileTmp.delete();
    return null;
  }

  Future<Uint8List> downloadFileById(String fileId) async {
    Uint8List result;
    try {
      final request = await _request;
      if (loginFailed) return null;
      final driveV3.Media file = await request.driver.files
          .get(fileId, downloadOptions: driveV3.DownloadOptions.FullMedia);
      List<int> dataStore = [];

      Completer<List<int>> completer = new Completer<List<int>>();
      file.stream.listen((data) {
        //_debug("DataReceived: ${data.length}", 2);
        dataStore.insertAll(dataStore.length, data);
      }, onDone: () {
        _debug("Task Done", 2);
        completer.complete(dataStore);
      }, onError: (error) {
        _debug("Some Error", 2);
        completer.complete(null);
      });
      final res = await completer.future;
      if (res != null)
        result = _userPassword != null
            ? _decryptData(Uint8List.fromList(res), _userPassword)
            : Uint8List.fromList(res);
    } catch (e) {
      print(e);
    }
    return result;
  }

  Future<bool> removeFileById(String fileId) async {
    try {
      AuthRequest request = await _request;
      await request.driver.files.delete(fileId);
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<String> _upload(File file, String mediaName) async {
    _debug('_upload[start]', 1);
    if (!_dataIsValid) {
      return null;
    }
    await _debugFile(file);
    final request = await _request;
    if (loginFailed) return null;
    _debug('_upload[_getFolder]', 2);
    final folder = await _getFolder(request);
    _debug('_upload[driveV3.File]', 2);
    final fileToUpload = new driveV3.File();
    fileToUpload.name = mediaName;
    _debug('_upload[_getFileId]', 2);
    final currentFileId = await _getFileId(request, mediaName);
    _debug('_upload[$currentFileId]', 2);
    if (currentFileId == null) fileToUpload.parents = [folder.id];
    _debug('_upload[driveV3.Media]', 2);
    final media = new driveV3.Media(file.openRead(), file.lengthSync());
    _debug('_upload[fileToUpload]', 2);
    final response = currentFileId != null
        ? await request.driver.files
            .update(fileToUpload, currentFileId, uploadMedia: media)
        : await request.driver.files.create(fileToUpload, uploadMedia: media);
    _debug('_upload[end="$mediaName"]:${response.id}', 1);
    return response.id;
  }

  Future<dynamic> _download(
      List<driveV3.File> files, String fileName, File saveFile) async {
    _debug('_download[start]', 1);
    //list.files[0].id;
    final request = await _request;
    final currentFile = files.firstWhere((element) => element.name == fileName,
        orElse: () => null);
    if (currentFile == null) return null;
    final fileId = currentFile.id;
    final driveV3.Media file = await request.driver.files
        .get(fileId, downloadOptions: driveV3.DownloadOptions.FullMedia);
    List<int> dataStore = [];

    Completer<List<int>> completer = new Completer<List<int>>();
    file.stream.listen((data) {
      //_debug("DataReceived: ${data.length}", 2);
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      _debug("Task Done", 2);
      completer.complete(dataStore);
    }, onError: (error) {
      _debug("Some Error", 2);
      completer.complete(null);
    });
    final res = await completer.future;
    await saveFile.writeAsBytes(res);
    await _debugFile(saveFile);
    _debug('_download[end]', 1);
    return saveFile;
  }

  Future<File> reload() async {
    _debug('reload[start]', 1);
    if (isLoading) return null;
    isLoading = true;
    AuthRequest request = await _request;
    if (loginFailed) {
      _debug('reload[retry]', 2);
      loginFailed = false;
      request = await _request;
      _debug('reload[loginFailed=$loginFailed]', 2);
      if (loginFailed) {
        isLoading = false;
        return null;
      }
    }
    try {
      final folder = await _getFolder(request);
      String query = "'${folder.id}' in parents";
      //final all = await request.driver.files.list();
      final list = await request.driver.files.list(q: query);
      _debug('reload[list=${list.files.length}]', 2);
      final abyssZipFile = list.files.firstWhere(
          (element) => element.name == ABYSS_ZIP_NAME,
          orElse: () => null);
      final abyssKeyFile = list.files.firstWhere(
          (element) => element.name == ABYSS_KEY_NAME,
          orElse: () => null);
      if (abyssZipFile == null || abyssKeyFile == null) {
        list.files.forEach((element) async {
          await request.driver.files.delete(element.id);
        });
        await _changeKey();

        final data = DEFAULT_DATA;
        final dbFile = await save(data);
        isLoading = false;
        return dbFile;
      }
      // TDOD: check.....
      final tmpDic = await _temporaryDirectory;
      final zipFile = File("$tmpDic/$ABYSS_ZIP_NAME");
      final zip = await _download(list.files, ABYSS_ZIP_NAME, zipFile);
      if (zip != null) {
        final dbFile = await _unzipFile(zipFile);
        await zipFile.delete();
        isLoading = false;
        return dbFile;
      }
    } catch (e, s) {
      printException(e, s);
    }
    final dbFile = await save({});
    isLoading = false;
    return dbFile;
  }

  Future<File> getTemporayFile(String fileId) async {
    final tmpDic = await _temporaryDirectory;
    return File("$tmpDic/$fileId.jpg");
  }

  Future<String> get _temporaryDirectory async {
    _debug('_temporaryDirectory[start]', 1);
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<Directory> _emptyFolder(Directory folder) async {
    _debug('_emptyFolder[start]', 1);
    if (folder.existsSync()) {
      try {
        await folder.delete(recursive: true);
      } catch (e, s) {
        _debug('_emptyFolder[catch]', 2);
        printException(e, s);
      }
    }
    await folder.create();
    _debug('_emptyFolder[end]', 1);
    return folder;
  }

  Future<File> _zipFile(File dbFile) async {
    _debug('_zipFile[start]', 1);
    final tmpDic = await _temporaryDirectory;
    final backupDic = "$tmpDic/$ABYSS_BACKUP_FOLDER/";
    final backup = await _emptyFolder(Directory(backupDic));

    await dbFile.copy("$backupDic/${basename(dbFile.path)}");
    final zipFile = File("$tmpDic/$ABYSS_ZIP_NAME");

    try {
      await ZipFile.createFromDirectory(
          sourceDir: backup, zipFile: zipFile, includeBaseDirectory: true);
      _debug('_zipFile[end]', 1);
      return zipFile;
    } catch (e, s) {
      printException(e, s);
    }
    _debug('_zipFile[end]', 1);
    return null;
  }

  Future<File> _unzipFile(File zipFile) async {
    _debug('_unzipFile[start]', 1);
    final tmpDic = await _temporaryDirectory;
    final backupDic = "$tmpDic/$ABYSS_BACKUP_FOLDER";
    try {
      final backup = await _emptyFolder(Directory(backupDic));
      await ZipFile.extractToDirectory(
          zipFile: zipFile,
          destinationDir: backup,
          onExtracting: (zipEntry, progress) {
            print('   progress: ${progress.toStringAsFixed(1)}%');
            print('   name: ${zipEntry.name}');
            print('   isDirectory: ${zipEntry.isDirectory}');
            print(
                '   modificationDate: ${zipEntry.modificationDate.toLocal().toIso8601String()}');
            print('   uncompressedSize: ${zipEntry.uncompressedSize}');
            print('   compressedSize: ${zipEntry.compressedSize}');
            print('   compressionMethod: ${zipEntry.compressionMethod}');
            print('   crc: ${zipEntry.crc}');
            return ExtractOperation.extract;
          });
      final abyssFile =
          File("$backupDic/$ABYSS_BACKUP_FOLDER/$ABYSS_FILE_NAME");
      final path = await _localPath;
      final dbFile = await abyssFile.copy('$path/$ABYSS_FILE_NAME');
      await _debugFile(dbFile);
      return dbFile;
    } catch (e, s) {
      printException(e, s);
    }
    return null;
  }

  Future<String> get _localPath async {
    _debug('_localPath[start]', 1);
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> _getFileId(AuthRequest request, String fileName) async {
    final folder = await _getFolder(request);
    String query = "'${folder.id}' in parents";
    final list = await request.driver.files.list(q: query);
    final currentFile = list.files
        .firstWhere((element) => element.name == fileName, orElse: () => null);
    return currentFile != null ? currentFile.id : null;
  }

  Future<dynamic> _downloadFileContent(String fileName) async {
    _debug('_downloadFileContent[start]', 1);
    final request = await _request;
    final currentFileId = await _getFileId(request, fileName);
    if (currentFileId == null) return null;
    final driveV3.Media file = await request.driver.files
        .get(currentFileId, downloadOptions: driveV3.DownloadOptions.FullMedia);
    List<int> dataStore = [];

    Completer<List<int>> completer = new Completer<List<int>>();
    file.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      _debug("Task Done", 2);
      completer.complete(dataStore);
    }, onError: (error) {
      _debug("Some Error", 2);
      completer.complete(null);
    });
    final charCodes = await completer.future;
    _debug('_downloadFileContent[end]', 1);
    return new String.fromCharCodes(charCodes);
  }

  Future<dynamic> _changeKey() async {
    final keyPair = Box.keyPair();
    _publicKey = keyPair.publicKey;
    _secretKey = keyPair.secretKey;
    Map<String, dynamic> _key = {
      "publicKey": TweetNaclFast.hexEncodeToString(_publicKey),
      "secretKey": TweetNaclFast.hexEncodeToString(_secretKey)
    };
    final file = await _keyFile;
    if (_userPassword != null && _userPassword.length > 0) {
      final content = _encryptMessage(json.encode(_key), _userPassword);
      _key = {"passwordRequired": true, "content": content};
      await file.writeAsString(json.encode(_key));
    } else {
      await file.writeAsString(json.encode(_key));
    }
    await _debugFile(file);

    _dataIsValid = true;
    try {
      await _upload(file, ABYSS_KEY_NAME);
      await file.delete();
    } catch (e) {
      _dataIsValid = false;
    }
  }

  Future<void> renew(Map<String, dynamic> obj) async {
    if (_dataIsValid) {
      await _changeKey();
      await save(obj);
    }
  }

  Future<void> getKey() async {
    _debug('getKey[start]', 1);
    if (!_dataIsValid || _publicKey != null) return;
    _dataIsValid = false;
    try {
      String contents = await _downloadFileContent(ABYSS_KEY_NAME);
      Map<String, dynamic> _key = jsonDecode(contents);
      if (_key.containsKey("passwordRequired")) {
        contents = _decryptMessage(_key["content"], _userPassword);
        _key = jsonDecode(contents);
      }
      _publicKey = TweetNaclFast.hexDecode(_key["publicKey"]);
      _secretKey = TweetNaclFast.hexDecode(_key["secretKey"]);
      _dataIsValid = true;
    } catch (e, s) {
      printException(e, s);
    }
  }

  Future<Box> getBox() async {
    _debug('getBox[start]', 1);
    await getKey();
    return Box(_publicKey, _secretKey);
  }

  Future<File> get _localFile async {
    _debug('_localFile[start]', 1);
    final path = await _localPath;
    final file = File('$path/$ABYSS_FILE_NAME');
    return file;
  }

  Future<File> get _keyFile async {
    _debug('_localFile[start]', 1);
    final path = await _localPath;
    final file = File('$path/$ABYSS_KEY_NAME');
    return file;
  }

  Future<File> save(Map<String, dynamic> obj) async {
    _debug('save[start]', 1);
    if (!_dataIsValid) {
      return null;
    }
    try {
      final file = await _localFile;
      final ejson = await _encrypt(obj);
      await file.writeAsString(json.encode(ejson));
      await _debugFile(file);
      final zipFile = await _zipFile(file);
      await _debugFile(zipFile);
      await _upload(zipFile, ABYSS_ZIP_NAME);
      await zipFile.delete();
      final tmpDic = await _temporaryDirectory;
      final backupDic = "$tmpDic/$ABYSS_BACKUP_FOLDER/";
      await _emptyFolder(Directory(backupDic));
      _debug('save[end]', 1);
      return file;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Map<String, dynamic>> load() async {
    if (!_dataIsValid) {
      return null;
    }
    _debug('load[start],isLoading = $isLoading', 1);
    if (isLoading) return {};
    isLoading = true;
    try {
      final file = await _localFile;
      await _debugFile(file);
      String contents = await file.readAsString();
      Map<String, dynamic> ejson = json.decode(contents);
      final d = await _decrypt(ejson);
      _debug('load[end]', 1);
      isLoading = false;
      return d;
    } catch (e, s) {
      printException(e, s);
    }
    isLoading = false;
    _debug('load[end]', 1);
    return null;
  }

  Future<Map<String, dynamic>> _decrypt(Map<String, dynamic> obj) async {
    _debug('_decrypt[start]', 1);
    final ciphertext = base64.decode(obj["ciphertext"]);
    final nonce = base64.decode(obj["nonce"]);

    final bobBox = await getBox();
    final message = bobBox.open_nonce(ciphertext, nonce);
    final data = utf8.decode(message);
    final response = json.decode(data);
    return response;
  }

  Future<Map<String, dynamic>> _encrypt(Map<String, dynamic> obj) async {
    _debug('_encrypt[start]', 1);
    String msgParams = json.encode(obj);
    final bobBox = await getBox();
    final nonce = TweetNaclFast.randombytes(24);
    final msgParamsUInt8Array = Uint8List.fromList(utf8.encode(msgParams));
    final encryptedMessage = bobBox.box_nonce(msgParamsUInt8Array, nonce);
    return {
      "ciphertext": base64.encode(encryptedMessage),
      "nonce": base64.encode(nonce)
    };
  }
}
