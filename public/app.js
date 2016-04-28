(function () {
	angular.module('StatusDashboard', [
		'ngMessages',
		'ngWebSocket'
	]).controller('RootCtrl', [
		'$scope',
		'$http',
		function ($scope, $http) {
			console.log("Setting up root controller");
		}
	]).service('statusService', [
		'$http',
		'$websocket',
		'websocketUri',
		function ($http, $websocket, websocketUri) {
			var status = {};

			var dataStream = $websocket(websocketUri);
			dataStream.onMessage(function(message) {
				var data = JSON.parse(message.data);
				Object.keys(data).forEach(function (key) {
					status[key] = data[key];
				});
			});

			return {
				getServiceStatus: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId]
						: null;
				}
			};
		}
	]).directive('icingaClassic', [
		'statusService',
		function (statusService) {
			var HOST_STATUSES = ['UP', 'DOWN', 'UNREACHABLE'];
			var SERVICE_STATUSES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN', 'DEPENDENT'];
			return {
				restrict: 'E',
				link:     function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getServiceStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						var hostStats = {};
						var hostStatus = {};
						var serviceStats = {};
						var serviceStatus = {};
						HOST_STATUSES.forEach(function (status) {
							hostStats[status] = 0;
							hostStatus[status] = false;
						});
						newValue.hosts.status.host_status.forEach(function (host) {
							hostStats[host.status]++;
							hostStatus[host.status] = true;
						});
						SERVICE_STATUSES.forEach(function (status) {
							serviceStats[status] = 0;
							serviceStatus[status] = false;
						});
						newValue.services.status.service_status.forEach(function (service) {
							serviceStats[service.status]++;
							serviceStatus[service.status] = true;
						});
						scope.hostStats = hostStats;
						scope.hostStatus = hostStatus;
						scope.serviceStats = serviceStats;
						scope.serviceStatus = serviceStatus;
					});
				},
				replace: false,
				templateUrl: 'templates/icinga-classic.html',
				scope: {
					statusId: '@statusId'
				}
			}
		}
	]).directive('redmineIssues', [
		'statusService',
		function (statusService) {
			return {
				restrict: 'E',
				link:     function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getServiceStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						scope.statusStats = [];
						var statusStats = {};
						newValue.issues.forEach(function (issue) {
							if (!statusStats[issue.status.id]) {
								statusStats[issue.status.id] = {
									id: issue.status.id,
									name: issue.status.name,
									count: 0
								};
								scope.statusStats.push(statusStats[issue.status.id]);
							}
							statusStats[issue.status.id].count++;
						});
						scope.issueCount = newValue.issues.length;
					});
				},
				replace: false,
				templateUrl: 'templates/redmine-issues.html',
				scope: {
					statusId: '@statusId'
				}
			}
		}
	]);
})();
