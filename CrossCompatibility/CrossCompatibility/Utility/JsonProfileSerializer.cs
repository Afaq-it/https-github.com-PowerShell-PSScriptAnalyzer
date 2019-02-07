// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.IO;
using Microsoft.PowerShell.CrossCompatibility.Data;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace Microsoft.PowerShell.CrossCompatibility.Utility
{
    /// <summary>
    /// Handles conversion of PowerShell compatibility profiles to and from JSON.
    /// </summary>
    public class JsonProfileSerializer
    {
        private readonly JsonSerializer _serializer;

        /// <summary>
        /// Create a new profile serializer with no whitespace/formatting inclusion.
        /// </summary>
        public static JsonProfileSerializer Create()
        {
            return Create(Formatting.None);
        }

        /// <summary>
        /// Create a new profile serializer with the given formatting configuration.
        /// </summary>
        /// <param name="formatting">The formatting option for any JSON output.</param>
        /// <returns>A new json profile serializer object.</returns>
        public static JsonProfileSerializer Create(Formatting formatting)
        {
            var settings = new JsonSerializerSettings()
            {
                Formatting = formatting,
                Converters = GetFormatConverters(),
            };

            var serializer = JsonSerializer.Create(settings);

            return new JsonProfileSerializer(serializer);
        }

        /// <summary>
        /// Create a new json profile serializer from the given JSON serializer.
        /// </summary>
        /// <param name="serializer">The json serializer to use.</param>
        private JsonProfileSerializer(JsonSerializer serializer)
        {
            _serializer = serializer;
        }

        /// <summary>
        /// Serialize a given .NET object to JSON.
        /// </summary>
        /// <param name="data">The object to serialize.</param>
        /// <returns>A string containing the JSON-encoded object data.</returns>
        public string Serialize(object data)
        {
            var writer = new StringWriter();
            _serializer.Serialize(writer, data);
            return writer.ToString();
        }

        /// <summary>
        /// Serialize a given .NET object to a file directly.
        /// </summary>
        /// <param name="data">The .NET object to serialize.</param>
        /// <param name="filePath">The path of the file to serialize to.</param>
        public void SerializeToFile(object data, string filePath)
        {
            using (var fileStream = File.OpenWrite(filePath))
            using (var streamWriter = new StreamWriter(fileStream))
            {
                _serializer.Serialize(streamWriter, data);
            }
        }

        /// <summary>
        /// Hydrate a compatibility profile object from a given file.
        /// </summary>
        /// <param name="filePath">The absolute path to the file to hydrate from.</param>
        /// <returns>The compatibility profile .NET object.</returns>
        public CompatibilityProfileData DeserializeFromFile(string filePath)
        {
            using (var fileStream = File.OpenRead(filePath))
            using (var streamReader = new StreamReader(fileStream))
            {
                return Deserialize(streamReader);
            }
        }

        /// <summary>
        /// Deserialize a compatibility profile from a FileInfo object.
        /// </summary>
        /// <param name="file">The file info object pointing to the file to read from.</param>
        /// <returns>The hydrated compatibility profile as a .NET object.</returns>
        public CompatibilityProfileData DeserializeFromFile(FileInfo file)
        {
            return Deserialize(file);
        }

        /// <summary>
        /// Deserialize a compatibility profile directly from an in-memory string in .NET.
        /// </summary>
        /// <param name="jsonString">The string holding the JSON-encoded PowerShell compatibility profile.</param>
        /// <returns>A hydrated compatibility profile .NET object.</returns>
        public CompatibilityProfileData Deserialize(string jsonString)
        {
            using (var stringReader = new StringReader(jsonString))
            {
                return Deserialize(stringReader);
            }
        }

        /// <summary>
        /// Deserialize a compatibility profile from a FileInfo object.
        /// </summary>
        /// <param name="file">The file info object pointing to the file to read from.</param>
        /// <returns>The hydrated compatibility profile as a .NET object.</returns>
        public CompatibilityProfileData Deserialize(FileInfo file)
        {
            using (var fileStream = file.OpenRead())
            using (var streamReader = new StreamReader(fileStream))
            {
                return Deserialize(streamReader);
            }
        }

        /// <summary>
        /// Deserialize a compatibility profile from a text reader object.
        /// </summary>
        /// <param name="textReader">The text reader to read JSON data from to hydrate the compatibility profile.</param>
        /// <returns>The hydrated compatibility profile as a .NET object.</returns>
        public CompatibilityProfileData Deserialize(TextReader textReader)
        {
            return _serializer.Deserialize<CompatibilityProfileData>(new JsonTextReader(textReader));
        }

        private static IList<JsonConverter> GetFormatConverters()
        {
            return new List<JsonConverter>()
            {
                new VersionConverter(),
                new PowerShellVersionJsonConverter(),
                new StringEnumConverter()
            };
        }
    }
}