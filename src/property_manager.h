
#ifndef PROPERTY_MANAGER_H
#define PROPERTY_MANAGER_H

#include <godot_cpp/classes/node.hpp>

namespace godot {

class PropertyManager : public Node {
	GDCLASS(PropertyManager, Node);

  Dictionary records = Dictionary();
	Dictionary befores = Dictionary();
  int ticks_before_remove = 20;

  void apply_record(Dictionary p_records, String full_path, int index, bool use_before);
  void apply_value(Variant value, String full_path);

protected:
	static void _bind_methods();

public:
  enum LoadType {
    ROLLBACK,
    INTERPOLATION_BACKWARD,
    INTERPOLATION_FORWARD,
  };

  void initialize(int p_ticks_before_remove);
  void reset();
  void set_synced(int current_tick, Node *node, String property, Variant value, bool interpolate=false);
  Array network_process(int current_tick);
  Array save_state();
  void load_state(Array state_records, int load_type);
  void interpolate_state(Array before_records, Array after_records, float weight);
  void load_state_forward(Array state_records, Dictionary events);
  void load_events(Dictionary events);

	PropertyManager() {}
	~PropertyManager() {};
};

}

#endif
