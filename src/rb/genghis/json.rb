require 'mongo'
require 'json'

module Genghis
  class JSON
    class << self
      def as_json(object)
        enc(object, Array, Hash, BSON::OrderedHash, Genghis::Models::Query)
      end

      def encode(object)
        as_json(object).to_json
      end

      def decode(str)
        dec(::JSON.parse(str))
      end

      private

      def enc(o, *a)
        o = o.to_s if o.is_a? Symbol
        fail "invalid: #{o.inspect}" unless a.empty? or a.include? o.class
        case o
        when Genghis::Models::Query then enc(o.as_json)
        when Array then o.map { |e| enc(e) }
        when Hash then enc_hash(o.clone)
        when Time then thunk('ISODate', enc_time(o))
        when Regexp then thunk('RegExp', {'$pattern' => o.source, '$flags' => enc_re_flags(o.options)})
        when BSON::ObjectId then thunk('ObjectId', o.to_s)
        when BSON::DBRef then db_ref(o)
        when BSON::Binary then thunk('BinData', {'$subtype' => o.subtype, '$binary' => enc_bin_data(o)})
        when BSON::Timestamp then thunk('Timestamp', {'$t' => o.seconds, '$i' => o.increment})
        when Float then o.nan? ? {'$genghisType' => 'NaN'} : o
        else o
        end
      end

      def enc_time(o)
        # strip trailing microsecond zeros, because wtf.
        o.strftime('%FT%T.%LZ').sub(/\.?[0]{0,3}Z$/, 'Z')
      end

      def enc_hash(o)
        o.keys.each { |k| o[k] = enc(o[k]) }
        o
      end

      def thunk(name, value)
        {'$genghisType' => name, '$value' => value }
      end

      def enc_re_flags(opt)
        ((opt & Regexp::MULTILINE != 0) ? 'm' : '') + ((opt & Regexp::IGNORECASE != 0) ? 'i' : '')
      end

      def enc_bin_data(o)
        Base64.strict_encode64(o.to_s)
      end

      def db_ref(o)
        o = o.to_hash
        {'$ref' => o['$ns'], '$id' => enc(o['$id'])}
      end

      def dec(o)
        case o
        when Array then o.map { |e| dec(e) }
        when Hash then
          case o['$genghisType']
          when 'ObjectId'  then mongo_object_id o['$value']
          when 'ISODate'   then mongo_iso_date  o['$value']
          when 'RegExp'    then mongo_reg_exp   o['$value']
          when 'BinData'   then mongo_bin_data  o['$value']
          when 'Timestamp' then mongo_timestamp o['$value']
          when 'NaN'       then Float::NAN
          else o.merge(o) { |k, v| dec(v) }
          end
        else o
        end
      end

      def dec_re_flags(flags)
        f = flags || ''
        (f.include?('m') ? Regexp::MULTILINE : 0) | (f.include?('i') ? Regexp::IGNORECASE : 0)
      end

      def mongo_object_id(value)
        value.nil? ? BSON::ObjectId.new : BSON::ObjectId.from_string(value)
      end

      def mongo_iso_date(value)
        return Time.now if value.nil?

        # because Rails overrides DateTime.to_time to return a DateTime. Grr.
        d = DateTime.parse(value)
        Time.utc(d.year, d.month, d.day, d.hour, d.min, d.sec + d.sec_fraction)
      end

      def mongo_reg_exp(value)
        Regexp.new(value['$pattern'], dec_re_flags(value['$flags']))
      end

      def mongo_bin_data(value)
        BSON::Binary.new(Base64.decode64(value['$binary']), value['$subtype'])
      end

      def mongo_timestamp(value)
        BSON::Timestamp.new(value['$t'], value['$i'])
      end
    end
  end
end