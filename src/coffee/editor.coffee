###!
Custom interactive code editor and preview slide plugin for reveal.js
Written by: [John Yanarella](http://twitter.com/johnyanarella)
Copyright (c) 2012-2103 [CodeCatalyst, LLC](http://www.codecatalyst.com/).
Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
###

$preview = $(
	"""
	<div class="preview" style="width: 373px; height: 730px;">
		<iframe></iframe>
	</div>
	"""
)

showPreview = ( editor ) ->
	# Create the preview popup.
	Reveal.keyboardEnabled = false
	$preview.bPopup(
		positionStyle: 'fixed'
		onClose: ->
			Reveal.keyboardEnabled = true
			return
	)
	
	# Populate the iframe in the preview popup.
	previewFrame = $preview.children('iframe').get( 0 )
	preview = previewFrame.contentDocument or previewFrame.contentWindow.document
	preview.write( editor.getValue() )
	preview.close()
	return

creatorEditor = ( $targetSlide ) ->
	url = $targetSlide.data( 'source' )
	$.ajax(
		url: url
		dataType: 'json'
	).done(
		( data ) ->
			# Populate the slide.
			
			options =""
			for section in data.sections
				options += "<optgroup label=\"#{ section.title }\">"
				for step in section.steps
					options += "<option value=\"#{ step.url }\">#{ step.title }</option>"
				options += "</optgroup>"
			
			$targetSlide.append(
				"""
					<h2>#{ data.title }</h2>
					<textarea></textarea>
					<div style="display: inline-table; width: 820px;">
						<div style="display: table-cell; width: 410px; text-align: left;">
							<select class="editor-combo-box">
								#{ options }
							</select>
						</div>
						<div style="display: table-cell; width: 410px; text-align: right;">
							<button class="editor-preview-button">Preview</button>
						</div>
					</div>
					<img class="editor-loading-indicator" src="resource/image/LoadingIndicator.gif" width="32" height="32">
				"""
			)
			
			textArea = $targetSlide.find( 'textarea' )[ 0 ]
			$textArea = $(textArea)
			
			editor = CodeMirror.fromTextArea( textArea,
				mode: 'text/html'
				tabMode: 'indent'
				indentUnit: 4
				indentWithTabs: true
				lineNumbers: true
				
				extraKeys:
					"'>'": ( editor ) -> editor.closeTag( editor, '>' )
					"'/'": ( editor ) -> editor.closeTag( editor, '/' )
			)
			editor.setSize( $textArea.width(), $textArea.height() )
			editor.refresh()
			
			loadingIndicator = $targetSlide.find( 'img.editor-loading-indicator' )[ 0 ]
			$loadingIndicator = $(loadingIndicator)
			
			$targetSlide.find( 'select.editor-combo-box' ).on( 'change', ( event ) ->
				loadTemplate( editor, $loadingIndicator, $( event.target ).val() )
			)
			$targetSlide.find( "button.editor-preview-button" ).on( 'click', ( event ) ->
				showPreview( editor )
			)
			
			# Nasty hack - workaround for weird refresh issue that left some editors in a partially rendered state.
			Reveal.addEventListener( 'slidechanged', ( event ) ->
				editor.refresh()
			)
			
			loadTemplate( editor, $loadingIndicator, data.sections[ 0 ].steps[ 0 ].url )
			return
	).fail(
		( promise, type, message ) ->
			alert( message )
			return
	)
	return

loadTemplate = ( editor, $loadingIndicator, url ) ->
	$loadingIndicator.addClass( 'loading' )
	$.ajax(
		url: url
		dataType: 'text'
	).done(
		( template ) ->
			editor.setValue( template )
			return
	).fail(
		( promise, type, message ) ->
			alert( message )
			return
	).always(
		$loadingIndicator.removeClass( 'loading' )
	)
	return

$('section.editor').each( ( index, element ) ->
	$slide = $( element )
	creatorEditor( $slide )
)
