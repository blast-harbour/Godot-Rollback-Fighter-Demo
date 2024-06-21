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

#ifndef SYNC_BOOSTER_H
#define SYNC_BOOSTER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/object.hpp>

namespace godot {

class InputBufferFrame : public RefCounted {
	GDCLASS(InputBufferFrame, RefCounted);

	int64_t tick;
	Dictionary players;

protected:
	static void _bind_methods();

public:
	void set_tick(int64_t p_tick);
	int64_t get_tick() const;
	Dictionary get_player_input(int peer_id) const;
	bool is_player_input_predicted(int peer_id) const;
	Array get_missing_peers(const Dictionary& peers) const;
	bool is_complete(const Dictionary& peers) const;
	void add_input_for_player(int peer_id, Dictionary input, bool predicted);
	Dictionary get_players() const;

	InputBufferFrame() {};
	~InputBufferFrame() {};
};

class SyncBooster : public Node {
	GDCLASS(SyncBooster, Node);

	Dictionary clean_data_for_hashing_recursive(const Dictionary &input);
	uint32_t hash_special_array(const Array& input) const;
	uint32_t hash_special_dict(const Dictionary& input) const;

protected:
	static void _bind_methods();

public:
    Variant serialize(const Variant& value);
    Variant serialize_dictionary(const Dictionary& value);
    Variant serialize_array(const Array& value);
	Variant unserialize(const Variant& value);
	Variant unserialize_dictionary(const Dictionary& value);
	Variant unserialize_array(const Array& value);
	void call_load_state(const Dictionary& state);
	void call_network_process(const Ref<InputBufferFrame> &input_frame);
	void call_network_preprocess(const Ref<InputBufferFrame> &input_frame);
	void call_network_postprocess(const Ref<InputBufferFrame> &input_frame);
	Dictionary call_save_state();
	void call_interpolate_state(const Dictionary& from_state, const Dictionary& to_state, float weight);
	Dictionary call_get_local_input(int local_peer_id);
	Ref<InputBufferFrame> call_predict_missing_input(const Dictionary& peers_ticks_since_real_input, Ref<InputBufferFrame> input_frame, Ref<InputBufferFrame> previous_frame);
	Dictionary clean_data_for_hashing(const Dictionary &input);

	SyncBooster() {}
	~SyncBooster() {};
};

}

#endif
