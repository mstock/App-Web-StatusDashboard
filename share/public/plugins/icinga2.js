(function () {
	'use strict';

	var HOST_STATUSES = ['UP', 'DOWN', 'UNREACHABLE'];
	var SERVICE_STATUSES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN'];

	angular.module('StatusDashboard').directive('icinga2', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						var hostStats = {};
						var hostStatus = {};
						var serviceStats = {};
						var serviceStatus = {};
						HOST_STATUSES.forEach(function (status) {
							hostStats[status] = 0;
							hostStats[status + '_ACKNOWLEDGED'] = 0;
							hostStatus[status] = false;
						});
						newValue.hosts.forEach(function (host) {
							var hostState = HOST_STATUSES[host.host_state];
							hostStats[hostState]++;
							if (host.host_acknowledged === 1) {
								hostStats[hostState + '_ACKNOWLEDGED']++;
							}
							hostStatus[hostState] = true;
						});
						SERVICE_STATUSES.forEach(function (status) {
							serviceStats[status] = 0;
							serviceStats[status + '_ACKNOWLEDGED'] = 0;
							serviceStatus[status] = false;
						});
						newValue.services.forEach(function (service) {
							var serviceState = SERVICE_STATUSES[service.service_state];
							serviceStats[serviceState]++;
							if (service.service_acknowledged === 1) {
								serviceStats[serviceState + '_ACKNOWLEDGED']++;
							}
							serviceStatus[serviceState] = true;
						});
						scope.hostStats = hostStats;
						scope.hostStatus = hostStatus;
						scope.serviceStats = serviceStats;
						scope.serviceStatus = serviceStatus;
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/icinga.html',
				scope:       {
					statusId:    '@statusId',
					statusTitle: '@statusTitle'
				}
			}
		}
	]).directive('icinga2ServiceGrid', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						var problemServices = {};
						var problemHostServiceStates = {};
						newValue.services.forEach(function (service) {
							var serviceStatus = SERVICE_STATUSES[service.service_state];
							if (serviceStatus !== 'OK' && !(scope.hideAcknowledged && service.service_acknowledged === 1)) {
								var serviceId =
									service.service_display_name || service.service_description;
								problemServices[serviceId] = true;
								if (!problemHostServiceStates[service.host_name]) {
									problemHostServiceStates[service.host_name] = {};
								}
								problemHostServiceStates[service.host_name][serviceId] = {
									status: serviceStatus,
									acknowledged: service.service_acknowledged === 1
								};
							}
						});
						scope.problemServices = Object.keys(problemServices).sort();
						scope.problemHosts = Object.keys(problemHostServiceStates).sort();
						scope.problemHostServiceStates = problemHostServiceStates;
					});
					scope.$watch('hideAcknowledgedStr', function (newValue, oldValue) {
						scope.hideAcknowledged = scope.$eval(newValue);
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/icinga-service-grid.html',
				scope:       {
					statusId:            '@statusId',
					statusTitle:         '@statusTitle',
					hideAcknowledgedStr: '@hideAcknowledged'
				}
			}
		}
	]);
}());
