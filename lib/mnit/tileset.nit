# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Manage images that are tileset or glyphset (for bitmap fonts)
module tileset

import mnit::display

# Efficiently retrieve tiles in a big image
class TileSet
	# The image containing the tileset
	var image: Image

	# The witdh of a tile
	var width: Int

	# The height of a tile
	var height: Int

	init
	do
		self.nb_cols = image.width / width
		self.nb_rows = image.height / height

		for j in [0..nb_rows[ do
			for i in [0..nb_cols[ do
				subimages.add image.subimage(i*width,j*height,width,height)
			end
		end
	end

	# The number of columns of tiles in the image
	var nb_cols: Int is noinit

	# The number of rows of tiles in the image
	var nb_rows: Int is noinit

	# Cache for images of tiles
	var subimages = new Array[Image]

	# The subimage of given tile
	# Aborts if x or y are out of bound
	fun [](x,y: Int): Image
	do
		assert x >= 0 and x < nb_cols and y >= 0 and y <= nb_rows else print "{x}x{y}<?{nb_cols}x{nb_rows}"
		var idx = x + y * nb_cols
		return subimages[idx]
	end
end

# A monospace bitmap font where glyphs are stored in a tileset
class TileSetFont
	super TileSet

	# Each character in the image
	# in left->right, then top->bottom order
	# Use space (' ') for holes in the tileset
	var chars: String

	# Additional space to insert horizontally between characters
	# A negative value will display tile overlapped
	var hspace: Numeric = 0.0 is writable

	# Additional space to insert vertically between characters
	# A negative value will display tile overlapped
	var vspace: Numeric = 0.0 is writable

	# The glyph (tile) associated to the character `c` according to `chars`
	# Returns null if `c` is not in `chars`
	fun char(c: Char): nullable Image
	do
		var i = chars.index_of(c)
		if i == -1 then return null
		return subimages[i]
	end

	# Distance between the beginning of a letter tile and the beginning of the next letter tile
	fun advance: Numeric do return width.add(hspace)

	# Distance between the beginning and the end of the longest line of `text`
	fun text_width(text: String): Numeric
	do
		var lines = text.split('\n')
		if lines.is_empty then return 0

		var longest = 0
		for line in lines do longest = longest.max(line.length)

		return longest.mul(advance)
	end

	# Distance between the top of the first line to the bottom of the last line in `text`
	fun text_height(text: Text): Numeric
	do
		if text.is_empty then return 0

		var n_lines = text.chars.count('\n')
		return (n_lines+1).mul(height.add(vspace)).sub(vspace)
	end
end

redef class Display
	# Blit the text using a monospace bitmap font
	# '\n' are rendered as carriage return
	fun text(text: String, font: TileSetFont, x, y: Numeric)
	do
		x = x.to_f
		var cx = x
		var cy = y.to_f
		var sw = font.width.to_f + font.hspace.to_f
		var sh = font.height.to_f + font.vspace.to_f
		for c in text.chars do
			if c == '\n' then
				cx = x
				cy += sh
				continue
			end
			if c == ' ' then
				cx += sw
				continue
			end
			var image = font.char(c)
			if image != null then
				blit(image, cx, cy)
			end
			cx += sw
		end
	end
end
