class_name C_NetworkSyncDirty extends Component

## An ephemeral tag component.
## When the Server modifies an entity's transform or vital stats (like health), 
## the modifying system (e.g., ServerPhysicsSystem) attaches this tag.
## 
## At the end of the frame, the ServerStateSyncSystem queries for this tag,
## broadcasts the updated state to all clients, and removes the tag.
