
#include "property_manager.h"

//#include "core/method_bind_ext.gen.inc"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/variant/node_path.hpp>

namespace godot {

void PropertyManager::initialize(int p_ticks_before_remove) {
    ticks_before_remove = p_ticks_before_remove;
    add_to_group("network_sync");
}

void PropertyManager::reset() {
  records.clear();
  befores.clear();
}

void PropertyManager::set_synced(int current_tick, Node *node, String property, Variant value, bool interpolate) {
  String node_path = String(node->get_path());
  String full_path = node_path + ":" + property;
  NodePath index = NodePath(property);

  Variant value_to_store = value.duplicate();
  if (value.get_type() == Variant::Type::OBJECT) {
    Node *value_node = Object::cast_to<Node>(value);
    if (value_node) {
      value_to_store = value_node->get_path();
    }
  }

  if (!befores.has(full_path)) {
    befores[full_path] = node->get_indexed(index);
  }

  Array record = Array();
  int size = interpolate ? 3 : 2;
  record.resize(size);
  record[0] = current_tick + ticks_before_remove;
  record[1] = value_to_store;
  if (interpolate) {
    record[2] = true;
  }
  records[full_path] = record;

  node->set_indexed(index, value);
}

Array PropertyManager::network_process(int current_tick) {
  Array ret = Array();
  Array to_remove = Array();
  Array keys = records.keys();
  for (int i = 0; i < keys.size(); i++) {
    Variant key = keys[i];
    Array record = records[key];
    if (current_tick > int(record[0])) {
      to_remove.append(key);
      Array event = Array();
      event.append(key);
      event.append(record[1]);
      ret.append(event);
    }
  }
  for (int i = 0; i < to_remove.size(); i++) {
    String key = to_remove[i];
    records.erase(key);
    if (befores.has(key)) {
      befores.erase(key);
    }
  }
  return ret;
}

Array PropertyManager::save_state() {
  Array state = Array();
  state.append(records.duplicate());
  return state;
}

void PropertyManager::apply_value(Variant value, String full_path) {
  Node *node = get_node_or_null(full_path);
  if (!node) {
    return;
  }
  if (value.get_type() == Variant::Type::NODE_PATH) {
    value = get_node<Node>(NodePath(value));
  }
  NodePath index = NodePath(full_path);
  index = NodePath(index.get_concatenated_subnames());
  node->set_indexed(index, value);
}

void PropertyManager::load_state(Array state, int load_type) {
  Dictionary state_records = state[0];
  Array keys = records.keys();
  for (int i = 0; i < keys.size(); i++) {
    String full_path = keys[i];
    if (!state_records.has(full_path)) {
      if (load_type != INTERPOLATION_FORWARD) {
        // If something is missing by loading forward, do nothing, it's already applied
        // If something is not supposed to be there, apply the before value
        if (befores.has(full_path)) {
          apply_value(befores[full_path], full_path);
        }
      }
    }
    else {
      Array record = records[full_path];
      Array state_record = state_records[full_path];
      bool is_different_counter = int(record[0]) != int(state_record[0]);
      bool is_interpolated = state_record.size() > 2;
      if (is_different_counter || is_interpolated) {
        apply_value(state_record[1], full_path);
      }
    }
  }

  if (load_type == INTERPOLATION_FORWARD) {
    keys = state_records.keys();
    for (int i = 0; i < keys.size(); i++) {
      String full_path = keys[i];
      if (!records.has(full_path)) {
        Array state_record = state_records[full_path];
        apply_value(state_record[1], full_path);
      }
    }
  }

  records = state_records.duplicate();
}

void PropertyManager::interpolate_state(Array before_state, Array after_state, float weight) {
  Dictionary before_records = before_state[0];
  Dictionary after_records = after_state[0];
  Array keys = after_records.keys();
  for (int i = 0; i < keys.size(); i++) {
    String full_path = keys[i];
    Array after_record = after_records[full_path];
    bool is_not_interpolated = after_record.size() <= 2;
    if (is_not_interpolated || !before_records.has(full_path)) {
      continue;
    }
    Array before_record = before_records[full_path];
    if (int(before_record[0]) == int(after_record[0]) - 1) {
      apply_value(Math::lerp((float)before_record[1], (float)after_record[1], weight), full_path);
    }
  }
}

void PropertyManager::load_state_forward(Array state, Dictionary events) {
  Dictionary state_records = state[0];
  load_events(events);
  Array keys = state_records.keys();
  for (int i = 0; i < keys.size(); i++) {
    String full_path = keys[i];
    Array state_record = state_records[full_path];
    apply_value(state_record[1], full_path);
  }

  records = state_records.duplicate();
}

void PropertyManager::load_events(Dictionary events) {
  Array keys = events.keys();
  for (int i = 0; i < keys.size(); i++) {
    String full_path = keys[i];
    Variant value = events[full_path];
    apply_value(value, full_path);
  }
}

void PropertyManager::_bind_methods() {
  ClassDB::bind_method(D_METHOD("initialize", "p_ticks_before_remove"), &PropertyManager::initialize);
	ClassDB::bind_method(D_METHOD("network_process", "current_tick"), &PropertyManager::network_process);
  ClassDB::bind_method(D_METHOD("set_synced", "current_tick", "node", "property", "value", "interpolate"), &PropertyManager::set_synced);
	ClassDB::bind_method(D_METHOD("reset"), &PropertyManager::reset);
  ClassDB::bind_method(D_METHOD("save_state"), &PropertyManager::save_state);
  ClassDB::bind_method(D_METHOD("load_state", "state_records", "load_type"), &PropertyManager::load_state);
  ClassDB::bind_method(D_METHOD("interpolate_state", "records_before", "records_after", "weight"), &PropertyManager::interpolate_state);
  ClassDB::bind_method(D_METHOD("load_state_forward", "state_records", "events"), &PropertyManager::load_state_forward);
}

}