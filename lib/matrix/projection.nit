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

# Services on `Matrix` to transform and project 3D coordinates
module projection

intrude import matrix

redef class Matrix

	# Create an orthogonal projection matrix
	#
	# `left, right, bottom, top, near, far` defines the world clip planes.
	new orthogonal(left, right, bottom, top, near, far: Float)
	do
		var dx = right - left
		var dy = top - bottom
		var dz = far - near

		assert dx != 0.0 and dy != 0.0 and dz != 0.0

		var mat = new Matrix.identity(4)
		mat[0, 0] = 2.0 / dx
		mat[3, 0] = -(right + left) / dx
		mat[1, 1] = 2.0 / dy
		mat[3, 1] = -(top + bottom) / dy
		mat[2, 2] = 2.0 / dz
		mat[3, 2] = -(near + far) / dz
		return mat
	end

	# Create a perspective transformation matrix
	#
	# Using the given vertical `field_of_view_y` in radians, the `aspect_ratio`
	# and the `near`/`far` world distances.
	new perspective(field_of_view_y, aspect_ratio, near, far: Float)
	do
		var frustum_height = (field_of_view_y/2.0).tan * near
		var frustum_width = frustum_height * aspect_ratio

		return new Matrix.frustum(-frustum_width, frustum_width,
		                          -frustum_height, frustum_height,
		                          near, far)
	end

	# Create a frustum transformation matrix
	#
	# `left, right, bottom, top, near, far` defines the world clip planes.
	new frustum(left, right, bottom, top, near, far: Float)
	do
		var dx = right - left
		var dy = top - bottom
		var dz = far - near

		assert near > 0.0
		assert far > 0.0
		assert dx > 0.0
		assert dy > 0.0
		assert dz > 0.0

		var mat = new Matrix(4, 4)

		mat[0, 0] = 2.0 * near / dx
		mat[0, 1] = 0.0
		mat[0, 2] = 0.0
		mat[0, 3] = 0.0

		mat[1, 0] = 0.0
		mat[1, 1] = 2.0 * near / dy
		mat[1, 2] = 0.0
		mat[1, 3] = 0.0

		mat[2, 0] = (right + left) / dx
		mat[2, 1] = (top + bottom) / dy
		mat[2, 2] = -(near + far) / dz
		mat[2, 3] = -1.0

		mat[3, 0] = 0.0
		mat[3, 1] = 0.0
		mat[3, 2] = -2.0 * near * far / dz
		mat[3, 3] = 0.0

		return mat
	end

	# Apply a translation by `x, y, z` to this matrix
	fun translate(x, y, z: Float)
	do
		for i in [0..3] do
			self[3, i] = self[3,i] + self[0, i] * x + self[1, i] * y + self[2, i] * z
		end
	end

	# Apply scaling on `x, y, z` to this matrix
	fun scale(x, y, z: Float)
	do
		for i in [0..3] do
			self[0, i] = self[0, i] * x
			self[1, i] = self[1, i] * y
			self[2, i] = self[2, i] * z
		end
	end

	# Create a rotation matrix by `angle` around the vector defined by `x, y, z`
	new rotation(angle, x, y, z: Float)
	do
		var mat = new Matrix.identity(4)

		var mag = (x*x + y*y + z*z).sqrt
		var sin = angle.sin
		var cos = angle.cos

		if mag > 0.0 then
			x = x / mag
			y = y / mag
			z = z / mag

			var inv_cos = 1.0 - cos

			mat[0, 0] = inv_cos*x*x + cos
			mat[0, 1] = inv_cos*x*y - z*sin
			mat[0, 2] = inv_cos*z*x + y*sin

			mat[1, 0] = inv_cos*x*y + z*sin
			mat[1, 1] = inv_cos*y*y + cos
			mat[1, 2] = inv_cos*y*z - x*sin

			mat[2, 0] = inv_cos*z*x - y*sin
			mat[2, 1] = inv_cos*y*z + x*sin
			mat[2, 2] = inv_cos*z*z + cos
		end
		return mat
	end

	# Apply a rotation of `angle` radians around the vector `x, y, z`
	fun rotate(angle, x, y, z: Float)
	do
		var rotation = new Matrix.rotation(angle, x, y, z)
		var rotated = self * rotation
		self.items = rotated.items
	end
end
