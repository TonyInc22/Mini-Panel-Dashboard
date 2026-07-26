param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CycleOutput', 'ToggleMicrophone', 'SyncMicrophone', 'ValidateControls', 'Validate')]
    [string]$Action
)

$source = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;

namespace MiniPanelAudio
{
    internal enum EDataFlow
    {
        Render,
        Capture,
        All
    }

    internal enum ERole
    {
        Console,
        Multimedia,
        Communications
    }

    [Flags]
    internal enum DeviceState : uint
    {
        Active = 0x00000001
    }

    [ComImport]
    [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    internal class MMDeviceEnumeratorComObject
    {
    }

    [ComImport]
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator
    {
        [PreserveSig]
        int EnumAudioEndpoints(
            EDataFlow dataFlow,
            DeviceState stateMask,
            out IMMDeviceCollection devices);

        [PreserveSig]
        int GetDefaultAudioEndpoint(
            EDataFlow dataFlow,
            ERole role,
            out IMMDevice endpoint);

        [PreserveSig]
        int GetDevice(
            [MarshalAs(UnmanagedType.LPWStr)] string id,
            out IMMDevice device);

        [PreserveSig]
        int RegisterEndpointNotificationCallback(IntPtr client);

        [PreserveSig]
        int UnregisterEndpointNotificationCallback(IntPtr client);
    }

    [ComImport]
    [Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceCollection
    {
        [PreserveSig]
        int GetCount(out uint count);

        [PreserveSig]
        int Item(uint index, out IMMDevice device);
    }

    [ComImport]
    [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice
    {
        [PreserveSig]
        int Activate(
            ref Guid interfaceId,
            uint classContext,
            IntPtr activationParameters,
            [MarshalAs(UnmanagedType.IUnknown)] out object instance);

        [PreserveSig]
        int OpenPropertyStore(uint storageMode, IntPtr properties);

        [PreserveSig]
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);

        [PreserveSig]
        int GetState(out DeviceState state);
    }

    [ComImport]
    [Guid("5CDF2C82-841E-4546-9722-0CF74078229A")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioEndpointVolume
    {
        [PreserveSig]
        int RegisterControlChangeNotify(IntPtr notify);

        [PreserveSig]
        int UnregisterControlChangeNotify(IntPtr notify);

        [PreserveSig]
        int GetChannelCount(out uint channelCount);

        [PreserveSig]
        int SetMasterVolumeLevel(float levelDb, Guid eventContext);

        [PreserveSig]
        int SetMasterVolumeLevelScalar(float level, Guid eventContext);

        [PreserveSig]
        int GetMasterVolumeLevel(out float levelDb);

        [PreserveSig]
        int GetMasterVolumeLevelScalar(out float level);

        [PreserveSig]
        int SetChannelVolumeLevel(uint channel, float levelDb, Guid eventContext);

        [PreserveSig]
        int SetChannelVolumeLevelScalar(uint channel, float level, Guid eventContext);

        [PreserveSig]
        int GetChannelVolumeLevel(uint channel, out float levelDb);

        [PreserveSig]
        int GetChannelVolumeLevelScalar(uint channel, out float level);

        [PreserveSig]
        int SetMute([MarshalAs(UnmanagedType.Bool)] bool muted, IntPtr eventContext);

        [PreserveSig]
        int GetMute([MarshalAs(UnmanagedType.Bool)] out bool muted);
    }

    [ComImport]
    [Guid("294935CE-F637-4E7C-A41B-AB255460B862")]
    internal class PolicyConfigClientComObject
    {
    }

    [ComImport]
    [Guid("568B9108-44BF-40B4-9006-86AFE5B5A620")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPolicyConfigVista
    {
        [PreserveSig]
        int GetMixFormat([MarshalAs(UnmanagedType.LPWStr)] string deviceId, IntPtr format);

        [PreserveSig]
        int GetDeviceFormat(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            [MarshalAs(UnmanagedType.Bool)] bool defaultFormat,
            IntPtr format);

        [PreserveSig]
        int SetDeviceFormat(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            IntPtr endpointFormat,
            IntPtr mixFormat);

        [PreserveSig]
        int GetProcessingPeriod(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            [MarshalAs(UnmanagedType.Bool)] bool defaultPeriod,
            IntPtr defaultPeriodValue,
            IntPtr minimumPeriodValue);

        [PreserveSig]
        int SetProcessingPeriod(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            IntPtr period);

        [PreserveSig]
        int GetShareMode(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            IntPtr mode);

        [PreserveSig]
        int SetShareMode(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            IntPtr mode);

        [PreserveSig]
        int GetPropertyValue(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            IntPtr key,
            IntPtr value);

        [PreserveSig]
        int SetPropertyValue(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            IntPtr key,
            IntPtr value);

        [PreserveSig]
        int SetDefaultEndpoint(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            ERole role);

        [PreserveSig]
        int SetEndpointVisibility(
            [MarshalAs(UnmanagedType.LPWStr)] string deviceId,
            [MarshalAs(UnmanagedType.Bool)] bool visible);
    }

    public static class Controller
    {
        private const uint ClassContextAll = 23;

        private static string GetDefaultOutputId(ERole role)
        {
            IMMDeviceEnumerator enumerator =
                (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();

            IMMDevice currentDevice;
            Marshal.ThrowExceptionForHR(
                enumerator.GetDefaultAudioEndpoint(
                    EDataFlow.Render,
                    role,
                    out currentDevice));

            string currentId;
            Marshal.ThrowExceptionForHR(currentDevice.GetId(out currentId));
            return currentId;
        }

        public static string GetDefaultOutputId()
        {
            return GetDefaultOutputId(ERole.Multimedia);
        }

        public static string CycleOutput()
        {
            IMMDeviceEnumerator enumerator =
                (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();

            IMMDeviceCollection collection;
            Marshal.ThrowExceptionForHR(
                enumerator.EnumAudioEndpoints(
                    EDataFlow.Render,
                    DeviceState.Active,
                    out collection));

            uint count;
            Marshal.ThrowExceptionForHR(collection.GetCount(out count));
            if (count < 2)
            {
                throw new InvalidOperationException(
                    "At least two active audio output endpoints are required.");
            }

            var endpointIds = new List<string>();
            for (uint index = 0; index < count; index++)
            {
                IMMDevice device;
                Marshal.ThrowExceptionForHR(collection.Item(index, out device));

                string id;
                Marshal.ThrowExceptionForHR(device.GetId(out id));
                endpointIds.Add(id);
            }

            string currentId = GetDefaultOutputId(ERole.Multimedia);

            int currentIndex = endpointIds.FindIndex(
                id => string.Equals(id, currentId, StringComparison.OrdinalIgnoreCase));
            int nextIndex = currentIndex < 0
                ? 0
                : (currentIndex + 1) % endpointIds.Count;

            string nextId = endpointIds[nextIndex];
            SetDefaultEndpointForAllRoles(nextId);

            ERole[] roles =
            {
                ERole.Console,
                ERole.Multimedia,
                ERole.Communications
            };

            for (int attempt = 0; attempt < 10; attempt++)
            {
                bool switched = true;
                foreach (ERole role in roles)
                {
                    string roleId = GetDefaultOutputId(role);
                    if (!string.Equals(
                        roleId,
                        nextId,
                        StringComparison.OrdinalIgnoreCase))
                    {
                        switched = false;
                        break;
                    }
                }

                if (switched)
                {
                    return nextId;
                }

                Thread.Sleep(50);
            }

            throw new InvalidOperationException(
                "Windows accepted the output request but did not make the target endpoint the default.");
        }

        private static void SetDefaultEndpointForAllRoles(string deviceId)
        {
            IPolicyConfigVista policy =
                (IPolicyConfigVista)new PolicyConfigClientComObject();
            Marshal.ThrowExceptionForHR(
                policy.SetDefaultEndpoint(deviceId, ERole.Console));
            Marshal.ThrowExceptionForHR(
                policy.SetDefaultEndpoint(deviceId, ERole.Multimedia));
            Marshal.ThrowExceptionForHR(
                policy.SetDefaultEndpoint(deviceId, ERole.Communications));
        }

        private static IAudioEndpointVolume GetDefaultMicrophoneVolume(ERole role)
        {
            IMMDeviceEnumerator enumerator =
                (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();

            IMMDevice microphone;
            Marshal.ThrowExceptionForHR(
                enumerator.GetDefaultAudioEndpoint(
                    EDataFlow.Capture,
                    role,
                    out microphone));

            Guid endpointVolumeId = typeof(IAudioEndpointVolume).GUID;
            object endpointVolumeObject;
            Marshal.ThrowExceptionForHR(
                microphone.Activate(
                    ref endpointVolumeId,
                    ClassContextAll,
                    IntPtr.Zero,
                    out endpointVolumeObject));

            IAudioEndpointVolume endpointVolume =
                (IAudioEndpointVolume)endpointVolumeObject;
            return endpointVolume;
        }

        public static bool GetMicrophoneMuted()
        {
            IAudioEndpointVolume endpointVolume =
                GetDefaultMicrophoneVolume(ERole.Console);
            bool muted;
            Marshal.ThrowExceptionForHR(endpointVolume.GetMute(out muted));
            return muted;
        }

        public static bool ToggleMicrophone()
        {
            bool muted = GetMicrophoneMuted();
            bool newMutedState = !muted;
            ERole[] roles =
            {
                ERole.Console,
                ERole.Multimedia,
                ERole.Communications
            };

            foreach (ERole role in roles)
            {
                IAudioEndpointVolume endpointVolume =
                    GetDefaultMicrophoneVolume(role);
                Marshal.ThrowExceptionForHR(
                    endpointVolume.SetMute(newMutedState, IntPtr.Zero));
            }

            return newMutedState;
        }

        public static void ValidateControls()
        {
            IMMDeviceEnumerator enumerator =
                (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();
            IPolicyConfigVista policy =
                (IPolicyConfigVista)new PolicyConfigClientComObject();

            IMMDeviceCollection outputCollection;
            Marshal.ThrowExceptionForHR(
                enumerator.EnumAudioEndpoints(
                    EDataFlow.Render,
                    DeviceState.Active,
                    out outputCollection));

            uint outputCount;
            Marshal.ThrowExceptionForHR(
                outputCollection.GetCount(out outputCount));
            if (outputCount == 0)
            {
                throw new InvalidOperationException(
                    "No active audio output endpoints were found.");
            }

            ERole[] roles =
            {
                ERole.Console,
                ERole.Multimedia,
                ERole.Communications
            };

            foreach (ERole role in roles)
            {
                IMMDevice currentDevice;
                Marshal.ThrowExceptionForHR(
                    enumerator.GetDefaultAudioEndpoint(
                        EDataFlow.Render,
                        role,
                        out currentDevice));

                string currentId;
                Marshal.ThrowExceptionForHR(
                    currentDevice.GetId(out currentId));
                Marshal.ThrowExceptionForHR(
                    policy.SetDefaultEndpoint(currentId, role));
            }

            foreach (ERole role in roles)
            {
                IAudioEndpointVolume endpointVolume =
                    GetDefaultMicrophoneVolume(role);
                bool muted;
                Marshal.ThrowExceptionForHR(
                    endpointVolume.GetMute(out muted));
                Marshal.ThrowExceptionForHR(
                    endpointVolume.SetMute(muted, IntPtr.Zero));
            }
        }
    }
}
'@

function Update-RainmeterMicrophoneIcon {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Muted
    )

    $skinRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $configName = Split-Path -Leaf $skinRoot
    $rainmeterPath = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

    if (-not (Test-Path -LiteralPath $rainmeterPath)) {
        return
    }

    if ($Muted) {
        & $rainmeterPath '!ShowMeter' 'MeterQuickMicrophoneIconMuted' $configName
        & $rainmeterPath '!HideMeter' 'MeterQuickMicrophoneIconActive' $configName
    }
    else {
        & $rainmeterPath '!HideMeter' 'MeterQuickMicrophoneIconMuted' $configName
        & $rainmeterPath '!ShowMeter' 'MeterQuickMicrophoneIconActive' $configName
    }

    & $rainmeterPath '!UpdateMeter' 'MeterQuickMicrophoneIconMuted' $configName
    & $rainmeterPath '!UpdateMeter' 'MeterQuickMicrophoneIconActive' $configName
    & $rainmeterPath '!Redraw' $configName
}

function Write-AudioControlLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $logPath = Join-Path $PSScriptRoot 'AudioControl.log'
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $entry = '{0} [{1}] [{2}] {3}' -f $timestamp, $Action, $Level, $Message
    Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8
}

function Get-AudioEndpointFriendlyName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EndpointId
    )

    $endpointGuidMatch = [regex]::Match(
        $EndpointId,
        '(\{[0-9a-fA-F-]{36}\})$'
    )

    if (-not $endpointGuidMatch.Success) {
        return $EndpointId
    }

    $endpointGuid = $endpointGuidMatch.Groups[1].Value
    $propertyPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\{0}\Properties' -f $endpointGuid
    $propertyKey = Get-Item -LiteralPath $propertyPath -ErrorAction SilentlyContinue

    if ($null -eq $propertyKey) {
        return $EndpointId
    }

    $friendlyName = $propertyKey.GetValue(
        '{a45c254e-df1c-4efd-8020-67d146a850e0},2'
    )

    if ([string]::IsNullOrWhiteSpace([string]$friendlyName)) {
        return $EndpointId
    }

    return [string]$friendlyName
}

function Refresh-RainmeterAudioOutput {
    $skinRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $configName = Split-Path -Leaf $skinRoot
    $rainmeterPath = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

    if (-not (Test-Path -LiteralPath $rainmeterPath)) {
        Write-AudioControlLog -Level 'WARN' -Message 'Rainmeter.exe was not found; the Windows output changed, but the displayed device could not be refreshed.'
        return
    }

    & $rainmeterPath '!Refresh' $configName
}

if ($Action -eq 'CycleOutput') {
    Write-AudioControlLog -Level 'INFO' -Message (
        'Cycle requested (PID={0}, 64-bit={1}).' -f
        $PID,
        [Environment]::Is64BitProcess
    )
}

try {
    if (-not ('MiniPanelAudio.Controller' -as [type])) {
        Add-Type -TypeDefinition $source -Language CSharp
    }

    if ($Action -eq 'CycleOutput') {
        $previousOutputId = [MiniPanelAudio.Controller]::GetDefaultOutputId()
        $newOutputId = [MiniPanelAudio.Controller]::CycleOutput()
        $verifiedOutputId = [MiniPanelAudio.Controller]::GetDefaultOutputId()

        if (-not [string]::Equals(
            $newOutputId,
            $verifiedOutputId,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw 'The output changed during verification and no longer matches the selected endpoint.'
        }

        $previousOutputName = Get-AudioEndpointFriendlyName -EndpointId $previousOutputId
        $newOutputName = Get-AudioEndpointFriendlyName -EndpointId $newOutputId
        Write-AudioControlLog -Level 'SUCCESS' -Message (
            'Output changed from "{0}" to "{1}".' -f
            $previousOutputName,
            $newOutputName
        )
        Refresh-RainmeterAudioOutput
    }
    elseif ($Action -eq 'ToggleMicrophone') {
        $microphoneMuted = [MiniPanelAudio.Controller]::ToggleMicrophone()
        Update-RainmeterMicrophoneIcon -Muted $microphoneMuted
    }
    elseif ($Action -eq 'SyncMicrophone') {
        $microphoneMuted = [MiniPanelAudio.Controller]::GetMicrophoneMuted()
        Update-RainmeterMicrophoneIcon -Muted $microphoneMuted
    }
    elseif ($Action -eq 'ValidateControls') {
        [MiniPanelAudio.Controller]::ValidateControls()
    }
}
catch {
    Write-AudioControlLog -Level 'ERROR' -Message $_.Exception.ToString()
    exit 1
}
