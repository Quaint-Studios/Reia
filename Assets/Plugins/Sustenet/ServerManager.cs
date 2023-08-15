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
    using System;
    using UnityEngine;

    /// <summary>
    /// Creates and manages a Cluster Server.
    /// </summary>
    [RequireComponent(typeof(UnityThreadManager))]
    public class ServerManager : MonoBehaviour
    {
        public string ipAddress = "127.0.0.1";
        public ushort port = 6256;
        public Server server;

        private void SetupServer()
        {
            server.onConnection.Run += (id) => OnClientConnection(id);
            server.onDisconnection.Run += (id) => OnClientDisconnection(id);
            server.onReceived.Run += (data) => OnServerReceived(data);
        }

        /// <summary>
        /// Create the cluster server, set it up, and connect.
        /// </summary>
        void Start()
        {
            Debug.Log("Test");
            Debug.Log(System.IO.Directory.GetCurrentDirectory());
            Debug.Log(System.IO.Path.GetDirectoryName(System.IO.Directory.GetCurrentDirectory()));
            Sustenet.Utils.Utilities.InitializeClusterServer();

            Server.ExternalFuncs externalFuncs = new Server.ExternalFuncs(
                _IsGrounded: new Predicate<int>((id) => IsGrounded(id))
            );

            server = new Server(externalFuncs);
            SetupServer();
        }

        /// <summary>
        /// TODO: Add functionality.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        bool IsGrounded(int id)
        {
            return true;
        }

        #region Events
        /// <summary>
        /// Once a client has connected to this server, this will run.
        /// </summary>
        public void OnClientConnection(int id)
        {
            Debug.Log($"Client #{id} has connected.");
        }

        /// <summary>
        /// Ran whenever a client gracefully or forcefully disconnects.
        /// </summary>
        public void OnClientDisconnection(int id)
        {
            Debug.Log($"Client #{id} has disconnected.");
        }

        /// <summary>
        /// Whenever this cluster server receives data. The data type should be UDP?
        /// </summary>
        /// <param name="data">The data received.</param>
        public void OnServerReceived(byte[] data)
        {
            Debug.Log($"ServerUDP");
            Debug.Log(System.BitConverter.ToString(data));
        }
        #endregion
    }
}
