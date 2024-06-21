/*************************************************************************/
/* Copyright (c) 2021-2022 David Snopek                                  */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "sync_booster.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/templates/hashfuncs.hpp>

namespace godot {

void SyncBooster::_bind_methods() {
	ClassDB::bind_method(D_METHOD("serialize", "value"), &SyncBooster::serialize);
    ClassDB::bind_method(D_METHOD("serialize_dictionary", "value"), &SyncBooster::serialize_dictionary);
	ClassDB::bind_method(D_METHOD("serialize_array", "value"), &SyncBooster::serialize_array);
    ClassDB::bind_method(D_METHOD("unserialize", "value"), &SyncBooster::unserialize);
    ClassDB::bind_method(D_METHOD("unserialize_dictionary", "value"), &SyncBooster::unserialize_dictionary);
	ClassDB::bind_method(D_METHOD("unserialize_array", "value"), &SyncBooster::unserialize_array);
    ClassDB::bind_method(D_METHOD("call_load_state", "state"), &SyncBooster::call_load_state);
    ClassDB::bind_method(D_METHOD("call_network_process", "input_frame"), &SyncBooster::call_network_process);
	ClassDB::bind_method(D_METHOD("call_network_preprocess", "input_frame"), &SyncBooster::call_network_preprocess);
	ClassDB::bind_method(D_METHOD("call_network_postprocess", "input_frame"), &SyncBooster::call_network_postprocess);
    ClassDB::bind_method(D_METHOD("call_save_state"), &SyncBooster::call_save_state);
    ClassDB::bind_method(D_METHOD("call_interpolate_state", "from_state", "to_state", "weight"), &SyncBooster::call_interpolate_state);
    ClassDB::bind_method(D_METHOD("call_get_local_input"), &SyncBooster::call_get_local_input);
    ClassDB::bind_method(D_METHOD("call_predict_missing_input", "peers_ticks_since_real_input", "input_frame", "previous_frame"), &SyncBooster::call_predict_missing_input);
    ClassDB::bind_method(D_METHOD("clean_data_for_hashing"), &SyncBooster::clean_data_for_hashing);
    ClassDB::bind_method(D_METHOD("hash_special_dict", "dict"), &SyncBooster::hash_special_dict);
    ClassDB::bind_method(D_METHOD("hash_special_array", "array"), &SyncBooster::hash_special_array);
}

Variant SyncBooster::serialize(const Variant& value) {
    Variant::Type type = value.get_type();
    if (type == Variant::DICTIONARY) {
        return serialize_dictionary(value);
    }
    if (type == Variant::ARRAY) {
        return serialize_array(value);
    }
    return value;
}

Variant SyncBooster::serialize_dictionary(const Dictionary& value) {
    Dictionary serialized;
    Array keys = value.keys();
    for (int i = 0; i < keys.size(); i++) {
        Variant key = keys[i];
        serialized[key] = serialize(value[key]);
    }
    return serialized;
}

Variant SyncBooster::serialize_array(const Array& value) {
    Array serialized;
    serialized.resize(value.size());
    for (int i = 0; i < value.size(); i++) {
        serialized[i] = serialize(value[i]);
    }
    return serialized;
}

Variant SyncBooster::unserialize(const Variant& value) {
    Variant::Type type = value.get_type();
    if (type == Variant::DICTIONARY) {
        return unserialize_dictionary(value);
    }
    if (type == Variant::ARRAY) {
        return unserialize_array(value);
    }
    return value;
}

Variant SyncBooster::unserialize_dictionary(const Dictionary& value) {
    Dictionary unserialized;
    Array keys = value.keys();
    for (int i = 0; i < keys.size(); i++) {
        Variant key = keys[i];
        unserialized[key] = unserialize(value[key]);
    }
    return unserialized;
}

Variant SyncBooster::unserialize_array(const Array& value) {
    Array unserialized;
    unserialized.resize(value.size());
    for (int i = 0; i < value.size(); i++) {
        unserialized[i] = unserialize(value[i]);
    }
    return unserialized;
}

void SyncBooster::call_load_state(const Dictionary& state) {
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_load_state");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
        Script *script = Object::cast_to<Script>(node->get_script());
        if (script) {
            if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
                String path(node->get_path());
                if (state.has(path)) {
                    node->call("_load_state", state[path]);
                }
            }
        }
    }
}

void SyncBooster::call_network_process(const Ref<InputBufferFrame> &input_frame) {
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_process");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
		if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
            Script *script = Object::cast_to<Script>(node->get_script());
			if (script) {
				const Dictionary &player_input = input_frame->get_player_input(node->get_multiplayer_authority());
                node->call("_network_process", player_input.get(String(node->get_path()), Dictionary()));
            }
        }
    }
}

void SyncBooster::call_network_preprocess(const Ref<InputBufferFrame> &input_frame) {
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_preprocess");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
        if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
            Script *script = Object::cast_to<Script>(node->get_script());
            if (script) {
				const Dictionary &player_input = input_frame->get_player_input(node->get_multiplayer_authority());
                node->call("_network_preprocess", player_input.get(String(node->get_path()), Dictionary()));
            }
        }
    }
}

void SyncBooster::call_network_postprocess(const Ref<InputBufferFrame> &input_frame) {
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_postprocess");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
        if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
            Script *script = Object::cast_to<Script>(node->get_script());
            if (script) {
				const Dictionary &player_input = input_frame->get_player_input(node->get_multiplayer_authority());
                node->call("_network_postprocess", player_input.get(String(node->get_path()), Dictionary()));
            }
        }
    }
}


Dictionary SyncBooster::call_save_state() {
	Dictionary state;
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_save_state");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
        Script *script = Object::cast_to<Script>(node->get_script());
        if (script) {
            if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
                NodePath path = node->get_path();
                if (path != NodePath()) {
                    state[String(path)] = node->call("_save_state");
                }
            }
        }
    }
	return state;
}

void SyncBooster::call_interpolate_state(const Dictionary& from_state, const Dictionary& to_state, float weight) {
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_interpolate");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
        Script *script = Object::cast_to<Script>(node->get_script());
        if (script) {
            if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
                String path(node->get_path());
                if (from_state.has(path) && to_state.has(path)) {
                    node->call("_interpolate_state", from_state[path], to_state[path], weight);
                }
            }
        }
    }
}

Ref<InputBufferFrame> SyncBooster::call_predict_missing_input(const Dictionary& peers_ticks_since_real_input, Ref<InputBufferFrame> input_frame, Ref<InputBufferFrame> previous_frame) {
    if (input_frame->is_complete(peers_ticks_since_real_input)) {
        return input_frame;
    }
    if (!previous_frame.is_valid()) {
        previous_frame = Ref<InputBufferFrame>(memnew(InputBufferFrame()));
        previous_frame->set_tick(-1);
    }
    Array missing_peers = input_frame->get_missing_peers(peers_ticks_since_real_input);
    Dictionary missing_peers_predicted_input;
    for (int i = 0; i < missing_peers.size(); i++) {
        int peer_id = missing_peers[i];
        missing_peers_predicted_input[peer_id] = Dictionary();
    }
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_input");
    for (int i = 0; i < nodes.size(); i++) {
        Node *node = Object::cast_to<Node>(nodes[i]);
        int node_master = node->get_multiplayer_authority();
        if (!missing_peers.has(node_master)) {
            continue;
        }

        Dictionary previous_input = previous_frame->get_player_input(node_master);
        String node_path = String(node->get_path());
        Script *script = Object::cast_to<Script>(node->get_script());
        bool has_predict_network_input = script && script->has_method("_predict_remote_input");
        if (has_predict_network_input || previous_input.has(node_path)) {
            Dictionary previous_input_for_node = previous_input.get(node_path, Dictionary());
            int ticks_since_real_input = peers_ticks_since_real_input[node_master];
            Dictionary predicted_input_for_node = has_predict_network_input ? Dictionary(node->call("_predict_remote_input", previous_input_for_node, ticks_since_real_input)) : previous_input_for_node.duplicate();
            if (!predicted_input_for_node.is_empty()) {
                Dictionary predicted_input_for_peer = missing_peers_predicted_input[node_master];
                predicted_input_for_peer[node_path] = predicted_input_for_node;
            }
        }
    }

    Array keys = missing_peers_predicted_input.keys();
    for (int i = 0; i < keys.size(); i++) {
        int peer_id = keys[i];
        Dictionary predicted_input = missing_peers_predicted_input[peer_id];
        predicted_input["$"] = hash_special_dict(predicted_input);
        input_frame->add_input_for_player(peer_id, predicted_input, true);
    }

    return input_frame;
}

Dictionary SyncBooster::call_get_local_input(int local_peer_id) {
    Dictionary input;
    TypedArray<Node> nodes = get_tree()->get_nodes_in_group("network_sync_input");
    for (int i = 0; i < nodes.size(); i++) {
		Node *node = Object::cast_to<Node>(nodes[i]);
        Script *script = Object::cast_to<Script>(node->get_script());
        if (node->get_multiplayer_authority() == local_peer_id && script) {
            if (node->is_inside_tree() && !node->is_queued_for_deletion()) {
                Dictionary local_input = node->call("_get_local_input");
                if (!local_input.is_empty()) {
                    input[String(node->get_path())] = local_input;
                }
            }
        }
    }
	return input;
}

Dictionary SyncBooster::clean_data_for_hashing(const Dictionary &input) {
    Dictionary cleaned;
    Array keys = input.keys();
    for (int i = 0; i < keys.size(); i++) {
        Variant key = keys[i];
        NodePath path = NodePath(String(keys[i]));
        if (path != NodePath()) {
            cleaned[keys[i]] = clean_data_for_hashing_recursive(input[keys[i]]);
        }
    }
    return cleaned;
}

Dictionary SyncBooster::clean_data_for_hashing_recursive(const Dictionary &input) {
    Dictionary cleaned;
    Array keys = input.keys();
    for (int i = 0; i < keys.size(); i++) {
        Variant::Type type = keys[i].get_type();
        if (type == Variant::STRING) {
            String key(keys[i]);
            if (key[0] == '_') {
                continue;
            }
        }
        else if (type == Variant::INT) {
            int key(keys[i]);
            if (key < 0) {
                continue;
            }
        }
        Variant value = input[keys[i]];
        if (value.get_type() == Variant::DICTIONARY) {
            cleaned[keys[i]] = clean_data_for_hashing_recursive(value);
        }
        else {
            cleaned[keys[i]] = value;
        }
    }
    return cleaned;
}


uint32_t SyncBooster::hash_special_dict(const Dictionary& input) const {
    uint32_t h = hash_murmur3_one_32(Variant::DICTIONARY);

    Array keys = input.keys();
    Array values = input.values();
    for (int i = 0; i < keys.size(); i++) {
        Variant key = keys[i];
        Variant value = values[i];
        Variant::Type type_key = key.get_type();
        if (type_key == Variant::STRING) {
            String string_key(key);
            if (string_key.begins_with("_") || string_key == "$") {
                continue;
            }
        } else if (type_key == Variant::INT) {
            int int_key(key);
            if (int_key < 0) {
                continue;
            }
        } else if (type_key == Variant::DICTIONARY) {
            h = hash_murmur3_one_32(hash_special_dict(key), h);
        } else if (type_key == Variant::ARRAY) {
            h = hash_murmur3_one_32(hash_special_array(key), h);
        } else {
            h = hash_murmur3_one_32(key.recursive_hash(0), h);
        }

        Variant::Type type_value = value.get_type();
        if (type_value == Variant::DICTIONARY) {
            h = hash_murmur3_one_32(hash_special_dict(value), h);
        } else if (type_value == Variant::ARRAY) {
            h = hash_murmur3_one_32(hash_special_array(value), h);
        } else {
            h = hash_murmur3_one_32(value.recursive_hash(0), h);
        }
    }

    return hash_fmix32(h);
}


uint32_t SyncBooster::hash_special_array(const Array& input) const {
    uint32_t h = hash_murmur3_one_32(Variant::ARRAY);

    for (int i = 0; i < input.size(); i++) {
        Variant::Type type_value = input[i].get_type();
        if (type_value == Variant::DICTIONARY) {
            h = hash_murmur3_one_32(hash_special_dict(input[i]), h);
        } else if (type_value == Variant::ARRAY) {
            h = hash_murmur3_one_32(hash_special_array(input[i]), h);
        } else {
            h = hash_murmur3_one_32(input[i].recursive_hash(0), h);
        }
    }
    return hash_fmix32(h);
}


void InputBufferFrame::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_tick", "p_tick"), &InputBufferFrame::set_tick);
    ClassDB::bind_method(D_METHOD("get_tick"), &InputBufferFrame::get_tick);
    ClassDB::bind_method(D_METHOD("get_player_input", "peer_id"), &InputBufferFrame::get_player_input);
	ClassDB::bind_method(D_METHOD("is_player_input_predicted", "peer_id"), &InputBufferFrame::is_player_input_predicted);
    ClassDB::bind_method(D_METHOD("get_missing_peers", "peers"), &InputBufferFrame::get_missing_peers);
    ClassDB::bind_method(D_METHOD("add_input_for_player", "peer_id", "input", "predicted"), &InputBufferFrame::add_input_for_player);
    ClassDB::bind_method(D_METHOD("is_complete", "peers"), &InputBufferFrame::is_complete);
    ClassDB::bind_method(D_METHOD("get_players"), &InputBufferFrame::get_players);

    ADD_PROPERTY(PropertyInfo(Variant::INT, "tick"), "set_tick", "get_tick");
}

void InputBufferFrame::set_tick(int64_t p_tick) {
    tick = p_tick;
}

int64_t InputBufferFrame::get_tick() const {
    return tick;
}

Dictionary InputBufferFrame::get_players() const {
    return players;
}

Dictionary InputBufferFrame::get_player_input(int peer_id) const {
    if (players.has(peer_id)) {
        Array player_input = (Array) players[peer_id];
        return player_input[0];
    }
    return Dictionary();
}

bool InputBufferFrame::is_player_input_predicted(int peer_id) const {
    if (players.has(peer_id)) {
        Array player_input = (Array) players[peer_id];
        return player_input[1];
    }
    return true;
}

Array InputBufferFrame::get_missing_peers(const Dictionary& peers) const {
    Array missing;
    Array keys = peers.keys();
    for (int i = 0; i < keys.size(); i ++) {
        if (!players.has(keys[i])) {
            missing.append(keys[i]);
        }
        else {
            Array player_input = (Array) players[keys[i]];
            if (player_input[1]) {
                missing.append(keys[i]);
            }
        }
    }
    return missing;
}

bool InputBufferFrame::is_complete(const Dictionary& peers) const {
    Array keys = peers.keys();
    for (int i = 0; i < keys.size(); i ++) {
        if (!players.has(keys[i])) {
            return false;
        }
        else {
            Array player_input = (Array) players[keys[i]];
            if (player_input[1]) {
                return false;
            }
        }
    }
    return true;
}

void InputBufferFrame::add_input_for_player(int peer_id, Dictionary input, bool predicted) {
    Array player_input;
    player_input.append(input);
    player_input.append(predicted);
    players[peer_id] = player_input;
}

}
