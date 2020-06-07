import os
import grp, pwd
from werkzeug.utils import secure_filename

# TODO: files should be validated by magic bytes header as well as extension

VALID_IMAGE_EXTENSIONS = {'jpg', 'jpe', 'jpeg', 'png', 'gif', 'svg', 'bmp'}
VALID_VIDEO_EXTENSIONS = {'avi' 'flv' 'wmv' 'mov' 'mp4'}
VALID_AUDIO_EXTENSIONS = {'wav' 'mp3' 'aac' 'ogg' 'oga' 'flac'}
VALID_DOC_EXTENSIONS = {'txt' 'csv', 'rtf' 'odf' 'ods' 'gnumeric' 'abw' 'doc' 'docx' 'xls' 'xlsx'}
VALID_LOG_EXTENSIONS = {'log','pcap','pcapng'}

def isValidFile(filename, filetype='any'):
    """
    Verifies file type based on extension and type to verify against
    Returns true if extension is valid for filetype, false otherwise
    Throws ValueError when filetype can not be handled
    Filetypes currently supported are: [image | video | audio | doc | log | any]
    """

    if filetype == 'any':
        return '.' in filename and filename.rsplit('.', 1)[1] in VALID_IMAGE_EXTENSIONS.union(
            VALID_VIDEO_EXTENSIONS).union(VALID_AUDIO_EXTENSIONS).union(VALID_DOC_EXTENSIONS).union(VALID_LOG_EXTENSIONS)
    elif filetype == 'image':
        return '.' in filename and filename.rsplit('.', 1)[1] in VALID_IMAGE_EXTENSIONS
    elif filetype == 'video':
        return '.' in filename and filename.rsplit('.', 1)[1] in VALID_VIDEO_EXTENSIONS
    elif filetype == 'audio':
        return '.' in filename and filename.rsplit('.', 1)[1] in VALID_AUDIO_EXTENSIONS
    elif filetype == 'doc':
        return '.' in filename and filename.rsplit('.', 1)[1] in VALID_DOC_EXTENSIONS
    elif filetype == 'log':
        return '.' in filename and filename.rsplit('.', 1)[1] in VALID_LOG_EXTENSIONS
    else:
        raise ValueError('Validation of filetype: ' + filetype + ' is not supported')

def saveUpload(file, savedir, filetype):
    """
    Saves file from current request context to provided savedir
    Flashes message indicating success or fail
    Returns a Dict {status=[error|warning|success], message=[None|<message>], file=[None|<filename>]}
    """

    result = {'status': 'error', 'message': None, 'file': None}

    if not file or file.filename == '':
        result['status'] = 'warning'
        result['message'] = 'No file has been selected'
        return result

    # make dirs in path if they don't exist
    if not os.path.exists(savedir):
        os.makedirs(savedir)

    if not isValidFile(file.filename, filetype):
        result['status'] = 'error'
        result['message'] = 'Unable to save file, invalid file type'
        return result
    else:
        # save the file
        filename = secure_filename(file.filename)
        filepath = os.path.join(savedir, filename)
        file.save(filepath)

        # store the results
        result['status'] = 'success'
        result['message'] = 'File successfully uploaded'
        result['file'] = filename

    return result

def change_permissions_recursive(path, mode):
    for root, dirs, files in os.walk(path, topdown=False):
        for dir in [os.path.join(root,d) for d in dirs]:
            os.chmod(dir, mode)
    for file in [os.path.join(root, f) for f in files]:
            os.chmod(file, mode)

def change_owner(path,user,group):
    uid = pwd.getpwnam(user).pw_uid
    gid = grp.getgrnam(group).gr_gid
    os.chown(path, uid, gid)
