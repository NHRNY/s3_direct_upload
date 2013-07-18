#= require jquery-fileupload/jquery.ui.widget
#= require jquery-fileupload/load-image.min
#= require jquery-fileupload/canvas-to-blob.min
#= require jquery-fileupload/jquery.iframe-transport
#= require jquery-fileupload/jquery.fileupload
#= require jquery-fileupload/jquery.fileupload-process
#= require jquery-fileupload/jquery.fileupload-image

$ = jQuery

$.fn.S3Uploader = (options) ->

  # support multiple elements
  if @length > 1
    @each ->
      $(this).S3Uploader options

    return this

  $uploadForm = this

  settings =
    path: ''
    additional_data: null
    before_send: null
    remove_completed_progress_bar: true
    remove_failed_progress_bar: false
    image_max_width: 1200
    image_max_height: 1200

  $.extend settings, options

  current_files = []

  setUploadForm = ->
    $uploadForm.fileupload
      disableImageResize: /Android(?!.*Chrome)|Opera/.test(window.navigator && navigator.userAgent)
      imageMaxWidth: settings.image_max_width
      imageMaxHeight: settings.image_max_height
      disableImagePreview: true

      send: (e, data) ->
        file = data.files[0]
        if settings.before_send
          settings.before_send(file)

      start: (e) ->
        $uploadForm.trigger("s3_uploads_start", [e])

      done: (e, data) ->
        content = build_content_object $uploadForm, data.files[0], data.result
        $uploadForm.trigger("s3_upload_complete", [content])

      fail: (e, data) ->
        content = build_content_object $uploadForm, data.files[0], data.result
        content.error_thrown = data.errorThrown

        $uploadForm.trigger("s3_upload_failed", [content])

      formData: (form) ->
        data = form.serializeArray()
        fileType = ""
        if "type" of @files[0]
          fileType = @files[0].type
        data.push
          name: "Content-Type"
          value: fileType

        data[1].value = settings.path + data[1].value #the key
        data

  build_content_object = ($uploadForm, file, result) ->
    domain = $uploadForm.attr('action')
    content = {}
    if result # Use the S3 response to set the URL to avoid character encodings bugs
      path             = $('Key', result).text()
      split_path       = path.split('/')
      content.url      = domain + path
      content.filename = split_path[split_path.length - 1]
      content.filepath = split_path.slice(0, split_path.length - 1).join('/')
    else # IE8 and IE9 return a null result object so we use the file object instead
      path             = settings.path + $uploadForm.find('input[name=key]').val().replace('/${filename}', '')
      content.url      = domain + path + '/' + file.name
      content.filename = file.name
      content.filepath = path

    content.filename   = file.name
    content.filesize   = file.size if 'size' of file
    content.filetype   = file.type if 'type' of file
    content = $.extend content, settings.additional_data if settings.additional_data
    content

  #public methods
  @initialize = ->
    setUploadForm()
    this

  @path = (new_path) ->
    settings.path = new_path

  @additional_data = (new_data) ->
    settings.additional_data = new_data

  @initialize()
