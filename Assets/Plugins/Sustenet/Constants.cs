/**
 * Copyright (C) 2020 Quaint Studios, Kristopher Ali (Makosai) <kristopher.ali.dev@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace SustenetUnity
{
    using System.Text.RegularExpressions;

    public static class Constants
    {
        #region User Constants
        public const byte USER_LEN_MAX = 3;
        public const byte USER_LEN_MIN = 16;
        public static Regex USER_VALID_REGEX = new Regex(@"^[a-zA-Z0-9_]$");
        #endregion
    }
}